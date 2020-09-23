const js_busytex = 'dist/busytex.js';
const wasm_busytex = 'dist/busytex.wasm';

class BusytexPipeline
{
    constructor(buystex_wasm, print)
    {
        this.wasm_module_promise = fetch(busytex_wasm).then(WebAssembly.compileStreaming);
        this.print = print;
        
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

        const wasm_module = await this.wasm_module_promise, print = this.print;
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
                const ENV = Module.ENV, FS = Module.FS;
                init_fs(FS);
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
        for(const arguments of arguments_array)
        {
            exit_code = NOCLEANUP_callMain(Module_, arguments, print);
            Module_.setStatus(`EXIT_CODE: ${exit_code}`);
        }
        return [Module_.FS, exit_code];
    }

    async compile(tex, bib, print)
    {
        const project = '/home/web_user/example';
        const tex_path = project + '/example.tex';
        const bib_path = project + '/example.bib';
        const aux_path = project + '/example.aux';
    
        const xdv_path = tex_path.replace('.tex', '.xdv');

        const cmd_xetex = ['xetex', '--interaction=nonstopmode', '--halt-on-error', '--no-pdf', '--fmt', this.fmt_latex, tex_path];
        const cmd_bibtex8 = ['bibtex8', '--csfile', '/bibtex/88591lat.csf', 'example'];
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
            FS.mkdir(project);
            FS.writeFile(tex_path, tex, {encoding: 'utf-8'}); 
            if(bib != null)
                FS.writeFile(bib_path, bib, {encoding: 'utf-8'}); 
            FS.chdir(project);
        };

        const copy_project = FS =>
        {
            copytree(project, _FS_, FS);
            FS.chdir(project);
        };
        
        if(bib != null)
        {
            [_FS_, exit_code] = await this.run([cmd_xetex, cmd_bibtex8], this.init_env, init_project);
            [_FS_, exit_code] = await this.run([cmd_xetex], this.init_env, copy_project);
            [_FS_, exit_code] = await this.run([cmd_xetex, cmd_xdvipdfmx], this.init_env, copy_project);
        }
        else
        {
            [_FS_, exit_code] = await this.run([cmd_xetex, cmd_xdvipdfmx], this.init_env, init_project);
        }

        const pdf = _FS_.readFile(tex_path.replace('.tex', '.pdf'), {encoding: 'binary'});
        
        return pdf;
    }
}
