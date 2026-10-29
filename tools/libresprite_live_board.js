// Loaded after the native renderers. app.yield lets the editor repaint every step.
var liveDocument,liveImages=[],liveTarget=[],liveCanvas=[],liveRow=0,liveTime=0;
function onEvent(event){
    if(event==='init'){
        var reference,guardian;
        if(!LIVE.directions){
            var portrait=app.open(LIVE.portrait);reference=portrait.sprite.layer(0).cel(0).image.getImageData();
            var ally=app.open(LIVE.guardian);guardian=ally.sprite.layer(0).cel(0).image.getImageData();
        }
        liveDocument=app.open(LIVE.file);
        for(var layer=0;layer<3;layer++){liveCanvas.push(new Uint8Array(640*LIVE.height*4));liveTarget.push(new Uint8Array(640*LIVE.height*4));liveImages.push(liveDocument.sprite.layer(layer).cel(0).image);}
        var ids=LIVE.directions?['portador_cenital','recaudador','caldera','coro','prefecto','madre']:['portador','portador_cenital','prefecto','recaudador','caldera','coro','madre'];
        for(var slot=0;slot<(LIVE.directions?24:ids.length);slot++){
            var id=ids[LIVE.directions?Math.floor(slot/4):slot];N=id.indexOf('portador')===0?96:(id==='prefecto'?160:128);ORIGIN=id==='prefecto'?16:0;
            var arrays=[new Uint8Array(N*N*4),new Uint8Array(N*N*4),new Uint8Array(N*N*4)];
            renderProjection(arrays[0],arrays[1],arrays[2],{state:'walk',direction:LIVE.directions?['south','east','north','west'][slot%4]:(slot===0?'east':'south'),frame:2,count:8},id);
            var left=(slot%4)*160+(160-N)/2,top=Math.floor(slot/4)*160+(160-N)/2;
            for(var layer=0;layer<3;layer++)for(var y=0;y<N;y++)for(var x=0;x<N;x++){
                var src=(y*N+x)*4,dst=((top+y)*640+left+x)*4;
                for(var c=0;c<4;c++)liveTarget[layer][dst+c]=arrays[layer][src+c];
            }
        }
        // Actual allied guardian at the same pixel scale and foot height as the hero.
        if(!LIVE.directions)for(var y=0;y<64;y++)for(var x=0;x<64;x++){
            var src=(y*512+x)*4,dst=((49+y)*640+92+x)*4;
            for(var c=0;c<4;c++)liveTarget[0][dst+c]=guardian[src+c];
        }
        if(!LIVE.directions)for(var x=53;x<146;x++){var dst=(105*640+x)*4;for(var c=0;c<4;c++)liveTarget[0][dst+c]=[48,67,86,255][c];}
        // The actual manga portrait is shown for reference, never baked into sprites.
        if(!LIVE.directions)for(var y=0;y<144;y++)for(var x=0;x<144;x++){
            var sx=1024+Math.floor(x*512/144),sy=512+Math.floor(y*512/144),src=(sy*1536+sx)*4,dst=((168+y)*640+488+x)*4;
            for(var c=0;c<4;c++)liveTarget[0][dst+c]=reference[src+c];
        }
        liveTime=Date.now();app.yield();
    }else if(event==='yield'){
        if(Date.now()-liveTime<100){app.yield();return;}
        liveTime=Date.now();
        for(var layer=0;layer<3;layer++){
            for(var y=liveRow;y<Math.min(LIVE.height,liveRow+6);y++)for(var x=0;x<640;x++){var at=(y*640+x)*4;for(var c=0;c<4;c++)liveCanvas[layer][at+c]=liveTarget[layer][at+c];}
            liveImages[layer].putImageData(liveCanvas[layer]);
        }
        liveDocument.sprite.commit();liveRow+=6;
        if(liveRow<LIVE.height)app.yield();
        else {liveDocument.sprite.saveAs(LIVE.file);console.log('LIVE_BOARD_COMPLETE '+LIVE.file);}
    }
}
