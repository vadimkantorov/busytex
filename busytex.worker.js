importScripts('/busytex.pipeline.js');

onmessage = async ({data : {files, main_tex_path, bibtex, busytex_wasm, busytex_js}}) => 
{
    if(busytex_wasm && busytex_js)
        pipeline = new BusytexPipeline(busytex_js, busytex_wasm, msg => postMessage({log : msg}), BusytexWorkerScriptLoader);
    else if(files && pipeline)
        postMessage({pdf : await pipeline.compile(files, main_tex_path, bibtex)})
};
