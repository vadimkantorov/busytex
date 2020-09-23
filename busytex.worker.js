importScripts('/busytex.pipeline.js')
importScripts('/dist/busytex.js');

//pipeline = BusytexPipeline()

onmessage = async evt =>
{
    const {tex, bib} = evt.data;
    const pdf = await compile(tex, bib, msg => postMessage({log : msg}));
    postMessage({pdf : pdf});
}
