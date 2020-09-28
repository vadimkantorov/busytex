import { Guthub } from '/guthub.js'

export class Shell
{
    constructor(FS, terminal, compiler, editor, hash_auth_token, search_repo_path, helloworld, ui)
    {
        this.home = '/home/web_user';
        this.terminal = terminal;
        this.FS = FS;
        this.compiler = compiler;
        this.editor = editor;
        this.ui = ui;
        
        this.github_auth_token = hash_auth_token || ''
        if(this.github_auth_token.length > 1)
            this.github_auth_token = this.github_auth_token.slice(1);

        this.github_https_path = search_repo_path || '';
        if(this.github_https_path.length > 1)
            this.github_https_path = 'https://github.com' + this.github_https_path.slice(1);
        
        this.guthub = new Guthub(this.FS, this.github_auth_token, terminal.println);
        this.tic_ = 0;
        this.pdf_path = '';
    }

    async run()
    {
        this.FS.chdir(this.home);
        
        this.open('helloworld.pdf', this.helloworld);
        
        await this.onload();
        this.terminal.prompt();
    }

    tic()
    {
        this.tic_ = performance.now();
    }

    toc()
    {
        const elapsed = (performance.now() - this.tic_) / 1000.0;
        
        this.terminal.println(`Elapsed time: ${elapsed.toFixed(2)} sec`);
    }

    async onload()
    {
        if(this.github_https_path.length > 0)
        {
            const repo_path = await this.clone(this.github_https_path);
            this.cd(repo_path);
        }
    }

    open(file_path, contents)
    {
        if(file_path.endsWith('.pdf') || file_path.endsWith('.jpg') || file_path.endsWith('.png') || file_path.endsWith('.svg'))
        {
            contents = contents || this.FS.readFile(file_path, {encoding : 'binary'});
            
            if(file_path.endsWith('.svg'))
            {
                this.ui.imgpreview.src = 'data:image/svg+xml;base64,' + btoa(String.fromCharCode.apply(null, contents));
                [this.ui.imgpreview.hidden, this.ui.pdfpreview.hidden] = [false, true];
            }
            else if(file_path.endsWith('.png') || file_path.endsWith('.jpg'))
            {
                const ext = file_path.endsWith('.png') ? 'png' : 'jpg';
                this.ui.imgpreview.src = `data:image/${ext};base64,` + btoa(String.fromCharCode.apply(null, contents));
                [this.ui.imgpreview.hidden, this.ui.pdfpreview.hidden] = [false, true];
            }
            else if(file_path.endsWith('.pdf'))
            {
                this.ui.pdfpreview.src = URL.createObjectURL(new Blob([contents], {type: 'application/pdf'}));
                [this.ui.imgpreview.hidden, this.ui.pdfpreview.hidden] = [true, false];
            }
        }
        else
        {
            contents = contents || this.FS.readFile(file_path, {encoding : 'utf8'});
            this.editor.getModel().setValue(contents);
        }
    }

    help()
    {
        return ['help', 'latexmk', 'download', 'clear', 'pwd', 'ls', 'mkdir', 'cd', 'clone', 'push', 'open', 'save'].sort();
    }

    save(file_path, contents)
    {
        this.FS.writeFile(file_path, contents);
    }

    pwd(replace_home)
    {
        const cwd = this.FS ? this.FS.cwd() : this.home;
        return replace_home == true ? cwd.replace(this.home, '~') : cwd;    
    }
    
    clear()
    {
        this.terminal.write('\x1bc');
    }

    ls(path)
    {
        return Object.keys(this.FS.lookupPath(path || '.').node.contents);
    }
    
    cd(path)
    {
        //const expanduser = path => return path.replace('~', this.home);
        this.FS.chdir(path);
    }

    mkdir(path)
    {
        this.FS.mkdir(path);
    }

    async latexmk(tex_path)
    {
        this.println('Running in background...');
        this.tic();
        const traverse = (root, relative_dir_path) =>
        {
            let entries = [];
            for(const [name, entry] of Object.entries(this.FS.lookupPath(`${root}/${relative_dir_path}`, {parent : false}).node.contents))
            {
                const relative_path = `${relative_dir_path}/${name}`;
                const absolute_path = `${root}/${relative_path}`;
                if(entry.isFolder)
                    entries.push({path : relative_path}, ...traverse(root, relative_path));
                else
                    entries.push({path : relative_path, contents : this.FS.readFile(absolute_path, {encoding : 'binary'})});
            }
            return entries;
        };

        const pdf_path = tex_path.replace('.tex', '.pdf');
        const cwd = this.FS.cwd();
        console.assert(tex_path.endsWith('.tex'));
        console.assert(cwd.startsWith(this.home));
        
        const project_dir = cwd.split('/').slice(0, 4).join('/');
        const source_path = `${cwd}/${tex_path}`;
        const main_tex_path = source_path.slice(project_dir.length + 1);

        const files = traverse(project_dir, '.');
        this.pdf_path = pdf_path;
        this.compiler.postMessage({files : files, main_tex_path : main_tex_path});
        
        //const pdf = await this.compiler.compile(files, main_tex_path, bibtex);
        //this.FS.writeFile(pdf_path, pdf);
        //this.open(pdf_path, pdf);
    }

    async upload(file_path)
    {
        const fileupload = this.ui.fileupload;
        const reader = new FileReader();
        return new Promise((resolve, reject) =>
        {
            reader.onloadend = () => {
                this.FS.writeFile(file_path, new Uint8Array(reader.result));
                resolve(`Local file [${fileupload.files[0].name}] uploaded into [${file_path}]`);
            };
            fileupload.onchange = () => reader.readAsArrayBuffer(fileupload.files[0]);
            fileupload.click();
        });
    }

    download(file_path, mime)
    {
          mime = mime || "application/octet-stream";

          let content = this.FS.readFile(file_path);
          console.log(`Offering download of "${file_path}", with ${content.length} bytes...`);
          var a = document.createElement('a');
          a.download = file_path;
          a.href = URL.createObjectURL(new Blob([content], {type: mime}));
          a.style.display = 'none';
          document.body.appendChild(a);
          a.click();

          setTimeout(() => {
              document.body.removeChild(a);
              URL.revokeObjectURL(a.href);
          }, 2000);
    }
    
    async clone(https_path)
    {
        const repo_path = https_path.split('/').pop();
        await this.guthub.clone(https_path, repo_path);
        return repo_path;
    }

    async push(relative_file_path)
    {
        await this.guthub.push(relative_file_path, 'guthub');
    }
}
