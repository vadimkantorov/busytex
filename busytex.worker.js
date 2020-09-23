importScripts('/busytex.pipeline.js');
importScripts('/dist/busytex.js');

print = msg => postMessage({log : msg});

pipeline = new BusytexPipeline('/dist/busytex.wasm', print);

onmessage = async evt =>
{
    const {tex, bib} = evt.data;
    const pdf = await pipeline.compile(tex, bib, );
    postMessage({pdf : pdf});
}
