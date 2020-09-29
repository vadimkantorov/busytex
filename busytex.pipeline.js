function BusytexDefaultScriptLoader(src)
{
    return new Promise((resolve, reject) =>
    {
        let s = self.document.createElement('script');
        s.src = src;
        s.onload = resolve;
        s.onerror = reject;
        self.document.head.appendChild(s);
    });
}

function BusytexRequireScriptLoader(src)
{
    return new Promise(resolve => self.require([src], resolve));
}

function BusytexWorkerScriptLoader(src)
{
    return Promise.resolve(self.importScripts(src));
}

BusytexDataLoader = 
{
    //https://emscripten.org/docs/api_reference/module.html#Module.getPreloadedPackage
    //https://github.com/emscripten-core/emscripten/blob/master/tests/manual_download_data.html

    preRun : [],

    locateFile(remote_package_name)
    {
        return '/dist/' + remote_package_name
    },
};

class BusytexPipeline
{
    constructor(busytex_js, busytex_wasm, texlive_js, texmf_local, print, script_loader)
    {
        this.wasm_module_promise = fetch(busytex_wasm).then(WebAssembly.compileStreaming);
        this.em_module_promise = script_loader(busytex_js);
        for(const data_package_js of texlive_js)
            this.em_module_promise = this.em_module_promise.then(_ => script_loader(data_package_js));
        this.print = print;
        
        this.project_dir = '/home/web_user/project_dir/';
        this.bin_busytex = '/bin/busytex';
        this.fmt_latex = '/latex.fmt';
        this.dir_texmfdist = ['/texlive', '/texmf', ...texmf_local].map(texmf => (texmf.startsWith('/') ? '' : this.project_dir) + texmf + '/texmf-dist').join(':');
        this.cnf_texlive = '/texmf.cnf';
        this.dir_cnf = '/';
        this.dir_fontconfig = '/fontconfig';
        this.conf_fontconfig = 'texlive.conf';
        this.dir_bibtexcsf = '/bibtex';

        console.log('TEXMFDIST', this.dir_texmfdist);

        this.init_env = ENV =>
        {
            ENV.TEXMFDIST = this.dir_texmfdist;
            ENV.TEXMFCNF = this.dir_cnf;
            ENV.FONTCONFIG_PATH = this.dir_fontconfig;
            ENV.FONTCONFIG_FILE = this.conf_fontconfig;
        };
    }

    async run(arguments_array, init_env, init_fs, exit_early, pre_run)
    {
        const NOCLEANUP_callMain = (Module, args) =>
        {
            //https://github.com/lyze/xetex-js/blob/master/post.worker.js
            Module.setPrefix(args[0]);
            const entryFunction = Module['_main'];
            const argc = args.length+1;
            const argv = Module.stackAlloc((argc + 1) * 4);
            Module.HEAP32[argv >> 2] = Module.allocateUTF8OnStack(Module.thisProgram);
            for (let i = 1; i < argc; i++) 
                Module.HEAP32[(argv >> 2) + i] = Module.allocateUTF8OnStack(args[i - 1]);
            Module.HEAP32[(argv >> 2) + argc] = 0;

            try
            {
                entryFunction(argc, argv);
            }
            catch(e)
            {
                this.print('callMain: ' + e.message);
                return e.status;
            }
            
            return 0;
        }

        const print = this.print;
        //const wasm_module = await this.wasm_module_promise;
        //const em_module = await this.em_module_promise;
        const [wasm_module, em_module] = await Promise.all([this.wasm_module_promise, this.em_module_promise]);

        const Module =
        {
            noInitialRun : true,

            thisProgram : this.bin_busytex,
            
            totalDependencies: 0,
            
            prefix : "",
            
            preRun : [() =>
            {
                if(pre_run != false)
                {
                    Object.setPrototypeOf(BusytexDataLoader, Module);
                    self.LZ4 = Module.LZ4;
                    for(const preRun of BusytexDataLoader.preRun) 
                        preRun();
                }

                init_env(Module.ENV);
                init_fs(Module.PATH, Module.FS);
            }],

            instantiateWasm(imports, successCallback)
            {
                WebAssembly.instantiate(wasm_module, imports).then(successCallback);
            },
            
            print(text) 
            {
                Module.setStatus(Module.prefix + ' | stdout: ' + (arguments.length > 1 ?  Array.prototype.slice.call(arguments).join(' ') : text));
            },

            printErr(text)
            {
                Module.setStatus(Module.prefix + ' | stderr: ' + (arguments.length > 1 ?  Array.prototype.slice.call(arguments).join(' ') : text));
            },
            
            setPrefix(text)
            {
                this.prefix = text;
            },
            
            setStatus(text)
            {
                print((this.statusPrefix || '') + text);
            },
            
            monitorRunDependencies(left)
            {
                this.totalDependencies = Math.max(this.totalDependencies, left);
                Module.setStatus(left ? 'Preparing... (' + (this.totalDependencies-left) + '/' + this.totalDependencies + ')' : 'All downloads complete.');
            },
        };
        const Module_ = await busytex(Module);
        let exit_code = 0;
        const mem = Uint8Array.from(Module_.HEAPU8);
        for(const args of arguments_array)
        {
            exit_code = NOCLEANUP_callMain(Module_, args, print);
            Module_.setStatus(`EXIT_CODE: ${exit_code}`);

            if(exit_code != 0 && exit_early == true)
                break;
            
            Module_.HEAPU8.set(mem);
        }
        return [Module_.FS, exit_code];
    }

    async compile(files, main_tex_path, bibtex, exit_early)
    {
        const source_name = main_tex_path.slice(main_tex_path.lastIndexOf('/') + 1);
        const dirname = main_tex_path.slice(0, main_tex_path.length - source_name.length) || '.';
        const source_dir = `${this.project_dir}/${dirname}`;

        const tex_path = source_name;
        const xdv_path = source_name.replace('.tex', '.xdv');
        const pdf_path = source_name.replace('.tex', '.pdf');
        const log_path = source_name.replace('.tex', '.log');
        const aux_path = source_name.replace('.tex', '.aux');

        const cmd_xetex = ['xetex', '--interaction=nonstopmode', '--halt-on-error', '--no-pdf', '--fmt', this.fmt_latex, tex_path];
        const cmd_bibtex8 = ['bibtex8', aux_path]; 
        const cmd_xdvipdfmx = ['xdvipdfmx', '-vv', '-o', pdf_path, xdv_path];

        let [_FS_, exit_code] = [null, 0]
        let __FS__ = null;

        const init_project_dir = (PATH, FS) =>
        {
            FS.mkdir(this.project_dir);
            for(const {path, contents} of files.sort((lhs, rhs) => lhs['path'] < rhs['path'] ? -1 : 1))
            {
                const absolute_path = `${this.project_dir}/${path}`;
                
                if(contents == null)
                    FS.mkdir(absolute_path);
                else
                    FS.writeFile(absolute_path, contents);
            }
            FS.chdir(source_dir);
        };

        const proxy_project_dir = (PATH, FS) =>
        {
            FS.mkdir(this.project_dir);
            FS.mount(BusytexPROXYFS(PATH, FS), { root: this.project_dir , fs: _FS_}, this.project_dir);
            FS.chdir(source_dir);
        };
        
        const ansi_reset_sequence = '\x1bc';
        this.print(ansi_reset_sequence);
        this.print(`New compilation started: [${main_tex_path}]`);
        
        if(bibtex == null)
            bibtex = files.some(({path, contents}) => contents != null && path.endsWith('.bib'));
        if(exit_early == null)
            exit_early = true;

        if(bibtex == true)
        {
            const pre_run = true;
            [_FS_, exit_code] = await this.run([cmd_xetex, cmd_bibtex8, cmd_xetex, cmd_xetex, cmd_xdvipdfmx], this.init_env, init_project_dir, exit_early, pre_run);
            
            //[_FS_, exit_code] = await this.run([cmd_xetex, cmd_bibtex8], this.init_env, init_project_dir, exit_early, pre_run);
            //if(exit_code == 0 || exit_early != true)
            //    [_FS_, exit_code] = await this.run([cmd_xetex], this.init_env, proxy_project_dir, true, pre_run);
            //if(exit_code == 0 || exit_early != true)
            //    [_FS_, exit_code] = await this.run([cmd_xetex, cmd_xdvipdfmx], this.init_env, proxy_project_dir, exit_early, pre_run);
        }
        else
        {
            [_FS_, exit_code] = await this.run([cmd_xetex, cmd_xdvipdfmx], this.init_env, init_project_dir, exit_early);
        }

        const pdf = exit_code == 0 ? _FS_.readFile(pdf_path, {encoding: 'binary'}) : null;
        const log = _FS_.readFile(log_path, {encoding : 'utf8'});
        return {pdf : pdf, log : log};
    }
}


BusytexPROXYFS = (PATH, FS) => {
    const ERRNO_CODES = {
        E2BIG: 1,
        EACCES: 2,
        EADDRINUSE: 3,
        EADDRNOTAVAIL: 4,
        EADV: 122,
        EAFNOSUPPORT: 5,
        EAGAIN: 6,
        EALREADY: 7,
        EBADE: 113,
        EBADF: 8,
        EBADFD: 127,
        EBADMSG: 9,
        EBADR: 114,
        EBADRQC: 103,
        EBADSLT: 102,
        EBFONT: 101,
        EBUSY: 10,
        ECANCELED: 11,
        ECHILD: 12,
        ECHRNG: 106,
        ECOMM: 124,
        ECONNABORTED: 13,
        ECONNREFUSED: 14,
        ECONNRESET: 15,
        EDEADLK: 16,
        EDEADLOCK: 16,
        EDESTADDRREQ: 17,
        EDOM: 18,
        EDOTDOT: 125,
        EDQUOT: 19,
        EEXIST: 20,
        EFAULT: 21,
        EFBIG: 22,
        EHOSTDOWN: 142,
        EHOSTUNREACH: 23,
        EIDRM: 24,
        EILSEQ: 25,
        EINPROGRESS: 26,
        EINTR: 27,
        EINVAL: 28,
        EIO: 29,
        EISCONN: 30,
        EISDIR: 31,
        EL2HLT: 112,
        EL2NSYNC: 156,
        EL3HLT: 107,
        EL3RST: 108,
        ELIBACC: 129,
        ELIBBAD: 130,
        ELIBEXEC: 133,
        ELIBMAX: 132,
        ELIBSCN: 131,
        ELNRNG: 109,
        ELOOP: 32,
        EMFILE: 33,
        EMLINK: 34,
        EMSGSIZE: 35,
        EMULTIHOP: 36,
        ENAMETOOLONG: 37,
        ENETDOWN: 38,
        ENETRESET: 39,
        ENETUNREACH: 40,
        ENFILE: 41,
        ENOANO: 104,
        ENOBUFS: 42,
        ENOCSI: 111,
        ENODATA: 116,
        ENODEV: 43,
        ENOENT: 44,
        ENOEXEC: 45,
        ENOLCK: 46,
        ENOLINK: 47,
        ENOMEDIUM: 148,
        ENOMEM: 48,
        ENOMSG: 49,
        ENONET: 119,
        ENOPKG: 120,
        ENOPROTOOPT: 50,
        ENOSPC: 51,
        ENOSR: 118,
        ENOSTR: 100,
        ENOSYS: 52,
        ENOTBLK: 105,
        ENOTCONN: 53,
        ENOTDIR: 54,
        ENOTEMPTY: 55,
        ENOTRECOVERABLE: 56,
        ENOTSOCK: 57,
        ENOTSUP: 138,
        ENOTTY: 59,
        ENOTUNIQ: 126,
        ENXIO: 60,
        EOPNOTSUPP: 138,
        EOVERFLOW: 61,
        EOWNERDEAD: 62,
        EPERM: 63,
        EPFNOSUPPORT: 139,
        EPIPE: 64,
        EPROTO: 65,
        EPROTONOSUPPORT: 66,
        EPROTOTYPE: 67,
        ERANGE: 68,
        EREMCHG: 128,
        EREMOTE: 121,
        EROFS: 69,
        ESHUTDOWN: 140,
        ESOCKTNOSUPPORT: 137,
        ESPIPE: 70,
        ESRCH: 71,
        ESRMNT: 123,
        ESTALE: 72,
        ESTRPIPE: 135,
        ETIME: 117,
        ETIMEDOUT: 73,
        ETOOMANYREFS: 141,
        ETXTBSY: 74,
        EUNATCH: 110,
        EUSERS: 136,
        EWOULDBLOCK: 6,
        EXDEV: 75,
        EXFULL: 115,
    };
    const PROXYFS = 
    {
mount: function (mount) {
  return PROXYFS.createNode(null, '/', mount.opts.fs.lstat(mount.opts.root).mode, 0);
},
createNode: function (parent, name, mode, dev) {
  if (!FS.isDir(mode) && !FS.isFile(mode) && !FS.isLink(mode)) {
	throw new FS.ErrnoError(ERRNO_CODES.EINVAL);
  }
  var node = FS.createNode(parent, name, mode);
  node.node_ops = PROXYFS.node_ops;
  node.stream_ops = PROXYFS.stream_ops;
  return node;
},
realPath: function (node) {
  var parts = [];
  while (node.parent !== node) {
	parts.push(node.name);
	node = node.parent;
  }
  parts.push(node.mount.opts.root);
  parts.reverse();
  return PATH.join.apply(null, parts);
},
node_ops: {
  getattr: function(node) {
	var path = PROXYFS.realPath(node);
	var stat;
	try {
	  stat = node.mount.opts.fs.lstat(path);
	} catch (e) {
	  if (!e.code) throw e;
	  throw new FS.ErrnoError(ERRNO_CODES[e.code]);
	}
	return {
	  dev: stat.dev,
	  ino: stat.ino,
	  mode: stat.mode,
	  nlink: stat.nlink,
	  uid: stat.uid,
	  gid: stat.gid,
	  rdev: stat.rdev,
	  size: stat.size,
	  atime: stat.atime,
	  mtime: stat.mtime,
	  ctime: stat.ctime,
	  blksize: stat.blksize,
	  blocks: stat.blocks
	};
  },
  setattr: function(node, attr) {
	var path = PROXYFS.realPath(node);
	try {
	  if (attr.mode !== undefined) {
		node.mount.opts.fs.chmod(path, attr.mode);
		// update the common node structure mode as well
		node.mode = attr.mode;
	  }
	  if (attr.timestamp !== undefined) {
		var date = new Date(attr.timestamp);
		node.mount.opts.fs.utime(path, date, date);
	  }
	  if (attr.size !== undefined) {
		node.mount.opts.fs.truncate(path, attr.size);
	  }
	} catch (e) {
	  if (!e.code) throw e;
	  throw new FS.ErrnoError(ERRNO_CODES[e.code]);
	}
  },
  lookup: function (parent, name) {
	try {
	  var path = PATH.join2(PROXYFS.realPath(parent), name);
	  var mode = parent.mount.opts.fs.lstat(path).mode;
	  var node = PROXYFS.createNode(parent, name, mode);
	  return node;
	} catch(e) {
	  if (!e.code) throw e;
	  throw new FS.ErrnoError(ERRNO_CODES[e.code]);
	}
  },
  mknod: function (parent, name, mode, dev) {
	var node = PROXYFS.createNode(parent, name, mode, dev);
	// create the backing node for this in the fs root as well
	var path = PROXYFS.realPath(node);
	try {
	  if (FS.isDir(node.mode)) {
		node.mount.opts.fs.mkdir(path, node.mode);
	  } else {
		node.mount.opts.fs.writeFile(path, '', { mode: node.mode });
	  }
	} catch (e) {
	  if (!e.code) throw e;
	  throw new FS.ErrnoError(ERRNO_CODES[e.code]);
	}
	return node;
  },
  rename: function (oldNode, newDir, newName) {
	var oldPath = PROXYFS.realPath(oldNode);
	var newPath = PATH.join2(PROXYFS.realPath(newDir), newName);
	try {
	  oldNode.mount.opts.fs.rename(oldPath, newPath);
	} catch(e) {
	  if (!e.code) throw e;
	  throw new FS.ErrnoError(ERRNO_CODES[e.code]);
	}
  },
  unlink: function(parent, name) {
	var path = PATH.join2(PROXYFS.realPath(parent), name);
	try {
	  parent.mount.opts.fs.unlink(path);
	} catch(e) {
	  if (!e.code) throw e;
	  throw new FS.ErrnoError(ERRNO_CODES[e.code]);
	}
  },
  rmdir: function(parent, name) {
	var path = PATH.join2(PROXYFS.realPath(parent), name);
	try {
	  parent.mount.opts.fs.rmdir(path);
	} catch(e) {
	  if (!e.code) throw e;
	  throw new FS.ErrnoError(ERRNO_CODES[e.code]);
	}
  },
  readdir: function(node) {
	var path = PROXYFS.realPath(node);
	try {
	  return node.mount.opts.fs.readdir(path);
	} catch(e) {
	  if (!e.code) throw e;
	  throw new FS.ErrnoError(ERRNO_CODES[e.code]);
	}
  },
  symlink: function(parent, newName, oldPath) {
	var newPath = PATH.join2(PROXYFS.realPath(parent), newName);
	try {
	  parent.mount.opts.fs.symlink(oldPath, newPath);
	} catch(e) {
	  if (!e.code) throw e;
	  throw new FS.ErrnoError(ERRNO_CODES[e.code]);
	}
  },
  readlink: function(node) {
	var path = PROXYFS.realPath(node);
	try {
	  return node.mount.opts.fs.readlink(path);
	} catch(e) {
	  if (!e.code) throw e;
	  throw new FS.ErrnoError(ERRNO_CODES[e.code]);
	}
  },
},
stream_ops: {
  open: function (stream) {
	var path = PROXYFS.realPath(stream.node);
	try {
	  stream.nfd = stream.node.mount.opts.fs.open(path,stream.flags);
	} catch(e) {
	  if (!e.code) throw e;
	  throw new FS.ErrnoError(ERRNO_CODES[e.code]);
	}
  },
  close: function (stream) {
	try {
	  stream.node.mount.opts.fs.close(stream.nfd);
	} catch(e) {
	  if (!e.code) throw e;
	  throw new FS.ErrnoError(ERRNO_CODES[e.code]);
	}
  },
  read: function (stream, buffer, offset, length, position) {
	try {
	  return stream.node.mount.opts.fs.read(stream.nfd, buffer, offset, length, position);
	} catch(e) {
	  if (!e.code) throw e;
	  throw new FS.ErrnoError(ERRNO_CODES[e.code]);
	}
  },
  write: function (stream, buffer, offset, length, position) {
	try {
	  return stream.node.mount.opts.fs.write(stream.nfd, buffer, offset, length, position);
	} catch(e) {
	  if (!e.code) throw e;
	  throw new FS.ErrnoError(ERRNO_CODES[e.code]);
	}
  },
  llseek: function (stream, offset, whence) {
 const SEEK_SET =	0;
 const SEEK_CUR	=   1;
 const SEEK_END	=   2;
	var position = offset;
	if (whence === SEEK_CUR) {
	  position += stream.position;
	} else if (whence === SEEK_END) {
	  if (FS.isFile(stream.node.mode)) {
		try {
		  const stat_size = stream.node.node_ops.getattr(stream.node).size;
		  position += stat_size;
		} catch (e) {
		  throw new FS.ErrnoError(ERRNO_CODES[e.code]);
		}
	  }
	} 
    if (position < 0) {
                  throw new FS.ErrnoError(ERRNO_CODES.EINVAL);
                }
	return position;
  }
}
};
return PROXYFS;
};

