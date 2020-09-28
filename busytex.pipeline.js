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
        
        this.project_dir = '/home/web_user/project_dir';
        this.bin_busytex = '/bin/busytex';
        this.fmt_latex = '/latex.fmt';
        this.dir_texmfdist = '/texlive/texmf-dist:/texmf/texmf-dist:' + texmf_local.join(':') + ':';
        this.cnf_texlive = '/texmf.cnf';
        this.dir_cnf = '/';
        this.dir_fontconfig = '/fontconfig';
        this.conf_fontconfig = 'texlive.conf';
        this.dir_bibtexcsf = '/bibtex';

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
                Object.setPrototypeOf(BusytexDataLoader, Module);
                self.LZ4 = Module.LZ4;
                for(const preRun of BusytexDataLoader.preRun) 
                    preRun();

                init_env(Module.ENV);
                init_fs(Module.FS);
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
        for(const args of arguments_array)
        {
            exit_code = NOCLEANUP_callMain(Module_, args, print);
            //TODO: break if not zero?
            Module_.setStatus(`EXIT_CODE: ${exit_code}`);
        }
        return [Module_.FS, exit_code];
    }

    async compile(files, main_tex_path, bibtex)
    {
        const source_name = main_tex_path.slice(main_tex_path.lastIndexOf('/') + 1);
        const dirname = main_tex_path.slice(0, main_tex_path.length - source_name.length) || '.';
        const source_dir = `${this.project_dir}/${dirname}`;

        const tex_path = source_name;
        const xdv_path = source_name.replace('.tex', '.xdv');
        const pdf_path = source_name.replace('.tex', '.pdf');
        const aux_path = source_name.replace('.tex', '.aux');

        const cmd_xetex = ['xetex', '--interaction=nonstopmode', '--halt-on-error', '--no-pdf', '--fmt', this.fmt_latex, tex_path];
        const cmd_bibtex8 = ['bibtex8', aux_path]; //'--csfile', '/bibtex/88591lat.csf'
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
        
        const init_project_dir = FS =>
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

        const copy_project_dir = FS =>
        {
            copytree(this.project_dir, _FS_, FS);
            FS.chdir(source_dir);
        };
        
        const ansi_reset_sequence = '\x1bc';
        this.print(ansi_reset_sequence);
        this.print(`New compilation started: [${main_tex_path}]`);
        if(bibtex)
        {
            //TODO: skip if not zero?
            [_FS_, exit_code] = await this.run([cmd_xetex, cmd_bibtex8], this.init_env, init_project_dir);
            [_FS_, exit_code] = await this.run([cmd_xetex], this.init_env, copy_project_dir);
            [_FS_, exit_code] = await this.run([cmd_xetex, cmd_xdvipdfmx], this.init_env, copy_project_dir);
        }
        else
        {
            [_FS_, exit_code] = await this.run([cmd_xetex, cmd_xdvipdfmx], this.init_env, init_project_dir);
        }

        return _FS_.readFile(pdf_path, {encoding: 'binary'});
    }
}
