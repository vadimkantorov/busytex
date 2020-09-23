function BusytexDefaultScriptLoader(src)
{
    return new Promise(function (resolve, reject)
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
    return self.require(src);
}

function BusytexWorkerScriptLoader(src)
{
    return Promise.resolve(self.importScripts(src));
}

class BusytexPipeline
{
    constructor(busytex_js, busytex_wasm, print, script_loader)
    {
        this.wasm_module_promise = fetch(busytex_wasm).then(WebAssembly.compileStreaming);
        this.em_module_promise = script_loader(busytex_js);
        this.print = print;
        
        this.project = '/home/web_user/project';
        this.bin_busytex = '/bin/busytex';
        this.fmt_latex = '/latex.fmt';
        this.dir_texmfdist = '/texlive/texmf-dist:';
        this.cnf_texlive = '/texmf.cnf';
        this.dir_cnf = '/';
        this.dir_fontconfig = '/fontconfig';
        this.conf_fontconfig = 'texlive.conf';

        this.init_env = ENV =>
        {
            ENV.TEXMFDIST = this.dir_texmfdist;
            ENV.TEXMFCNF = this.dir_cnf;
            ENV.FONTCONFIG_PATH = this.dir_fontconfig;
            ENV.FONTCONFIG_FILE = this.conf_fontconfig;
        };
    }

    async run(arguments_array, init_env, init_fs)
    {
        const NOCLEANUP_callMain = (Module, args) =>
        {
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
        const [wasm_module, em_module] = await Promise.all([this.wasm_module_promise, this.em_module_promise]);

        const Module =
        {
            instantiateWasm(imports, successCallback)
            {
                WebAssembly.instantiate(wasm_module, imports).then(successCallback);
            },
            
            noInitialRun : true,

            locateFile(remote_package_name)
            {
                return '/dist/' + remote_package_name
            },

            thisProgram : this.bin_busytex,

            preRun : [() =>
            {
                init_env(Module.ENV);
                init_fs(Module.FS);
            }],
            
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
            
            totalDependencies: 0,
            
            prefix : ""
        };
        
        const Module_ = await busytex(Module);
        let exit_code = 0;
        for(const args of arguments_array)
        {
            exit_code = NOCLEANUP_callMain(Module_, args, print);
            Module_.setStatus(`EXIT_CODE: ${exit_code}`);
        }
        return [Module_.FS, exit_code];
    }

    async compile(files, main_tex_path, bibtex)
    {
        const xdv_path = main_tex_path.replace('.tex', '.xdv');
        const pdf_path = main_tex_path.replace('.tex', '.pdf');
        const aux_path = main_tex_path.replace('.tex', '.aux');

        const cmd_xetex = ['xetex', '--interaction=nonstopmode', '--halt-on-error', '--no-pdf', '--fmt', this.fmt_latex, main_tex_path];
        const cmd_bibtex8 = ['bibtex8', '--csfile', '/bibtex/88591lat.csf', aux_path];
        const cmd_xdvipdfmx = ['xdvipdfmx', xdv_path];

        let [_FS_, exit_code] = [null, 0]
        
        const copytree = (file_path, src_FS, dst_FS) =>
        {
            dst_FS.mkdir(file_path);
            const files = src_FS.lookupPath(file_path).node.contents;
            for(const file_name of Object.keys(files))
            {
                const file = files[file_name];
                const path = `${file_path}/${file_name}`;
                if(!file.isFolder)
                    dst_FS.writeFile(path, src_FS.readFile(path, {encoding : 'binary'}));
                else
                    copytree(path, src_FS, dst_FS);
            }
        }
        
        const init_project = FS =>
        {
            FS.mkdir(this.project);
            for(const {path, type, contents} of files.sort((lhs, rhs) => lhs['path'] < rhs['path'] ? -1 : 1))
            {
                if(type == 'd')
                    FS.mkdir(this.project + '/' + path);
                else
                    FS.writeFile(this.project + '/' + path, contents);
            }
            FS.chdir(this.project);
        };

        const copy_project = FS =>
        {
            copytree(this.project, _FS_, FS);
            FS.chdir(this.project);
        };
        
        if(bibtex)
        {
            [_FS_, exit_code] = await this.run([cmd_xetex, cmd_bibtex8], this.init_env, init_project);
            [_FS_, exit_code] = await this.run([cmd_xetex], this.init_env, copy_project);
            [_FS_, exit_code] = await this.run([cmd_xetex, cmd_xdvipdfmx], this.init_env, copy_project);
        }
        else
        {
            [_FS_, exit_code] = await this.run([cmd_xetex, cmd_xdvipdfmx], this.init_env, init_project);
        }

        return _FS_.readFile(pdf_path, {encoding: 'binary'});
    }
}
