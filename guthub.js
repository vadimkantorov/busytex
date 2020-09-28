function delay(seconds)
{
    return new Promise(resolve => setTimeout(resolve, seconds * 1000));
}

function base64_encode_utf8(str)
{
    return btoa(encodeURIComponent(str).replace(/%([0-9A-F]{2})/g, function(match, p1) {return String.fromCharCode(parseInt(p1, 16)) }));
}

function network_error(resp)
{
    return new Error(`${resp.status}: ${resp.statusText}`);
}

export class Guthub
{
    constructor(FS, auth_token, println)
    {
        this.retry_delay_seconds = 2;
        this.auth_token = auth_token;
        this.println = println || (line => null);
        this.FS = FS;
    }

    github_api_request(https_path, relative_url, method, body)
    {
        const api = https_path.replace('github.com', 'api.github.com/repos');
        return fetch(api + relative_url, Object.assign({method : method || 'get', headers : Object.assign({Authorization : 'Basic ' + btoa(this.auth_token)}, body != null ? {'Content-Type' : 'application/json'} : {})}, body != null ? {body : JSON.stringify(body)} : {}));
    }

    read_https_path()
    {
        return this.FS.readFile('.git/config', {encoding : 'utf8'}).split('\n')[1].split(' ')[2];
    }

    read_githubcontents()
    {
        const path = '.git/githubapicontents.json';
        return Fthis.S.analyzePath(path).exists ? JSON.parse(FS.readFile(path, {encoding : 'utf8'})) : [];
    }
    
    async clone(https_path, repo_path)
    {
        this.println(`Cloning into '${repo_path}'...`);
        const resp = await this.github_api_request(https_path, '/contents');
        const repo = await resp.json();
        this.println(`remote: Enumerating objects: ${repo.length}, done.`);

        this.FS.mkdir(repo_path);
        this.FS.mkdir(repo_path + '/.git');
        this.FS.writeFile(repo_path + '/.git/config', '[remote "origin"]\nurl = ' + https_path);
        this.FS.writeFile(repo_path + '/.git/githubapicontents.json', JSON.stringify(repo));
        
        while(repo.length > 0)
        {
            const file = repo.pop();
            if(file.type == 'file')
            {
                const resp = await fetch(file.download_url);
                const contents = new Uint8Array(await resp.arrayBuffer());
                const file_path = repo_path + '/' + file.path;
                this.FS.writeFile(file_path, contents, {encoding: 'binary'});
            }
            else if(file.type == 'dir')
            {
                this.FS.mkdir(repo_path + '/' + file.path);
                const resp = await this.github_api_request(https_path, '/contents/' + file.path);
                const dir = await resp.json();
                repo.push(...dir);
            }
        }
        this.println(`Unpacking objects: 100% (${repo.length}/${repo.length}), done.`);
    }

    async push(file_path, message, retry)
    {
        const content = this.FS.readFile(file_path, {encoding : 'utf8'});
        let sha = this.read_githubcontents().filter(f => f.path == file_path);
        sha = sha.length > 0 ? sha[0].sha : null;
        const resp = await this.github_api_request(this.read_https_path(), '/contents/' + file_path, 'put', Object.assign({message : `${file_path}: ${message}`, content : base64_encode_utf8(content)}, sha ? {sha : sha} : {}));
        if(resp.ok)
            sha = (await resp.json()).content.sha;
        else if(resp.status == 409 && retry != false)
        {
            console.log('retry not implemented');
            //await delay(this.retry_delay_seconds);
            //await this.put(message, sha ? ((await this.init_doc()) || this.sha) : null, false);
        }
        else
            throw network_error(resp);
    }
}
