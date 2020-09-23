importScripts('/busytex.pipeline.js');

print = msg => postMessage({log : msg});

pipeline = new BusytexPipeline('/dist/busytex.wasm', '/dist/busytex.js', print, BusytexWorkerLoader);

onmessage = async evt =>
{
    const {tex, bib} = evt.data;
    const pdf = await pipeline.compile(tex, bib, );
    postMessage({pdf : pdf});
}
