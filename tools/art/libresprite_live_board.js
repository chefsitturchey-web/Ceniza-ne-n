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
            var id=ids[LIVE.directions?Math.floor(slot/4):slot];
            if(LIVE.painted&&LIVE.painted[id]){
                var info=LIVE.painted[id],sheet=app.open(LIVE.project_root+'/'+info.texture.substr(6)).sprite.layer(0).cel(0).image;
                var pixels=sheet.getImageData(),direction=LIVE.directions?slot%4:(slot===0?1:0),frame=direction*64+8;
                var scale=info.render_scale,extent=Math.round(info.cell*scale);
                var left=(slot%4)*160+(160-extent)/2,top=Math.floor(slot/4)*160+(160-extent)/2;
                for(var y=0;y<extent;y++)for(var x=0;x<extent;x++){
                    var sx=(frame%8)*info.cell+Math.floor(x/scale),sy=Math.floor(frame/8)*info.cell+Math.floor(y/scale);
                    var src=(sy*sheet.width+sx)*4,dst=((top+y)*640+left+x)*4;
                    for(var c=0;c<4;c++)liveTarget[0][dst+c]=pixels[src+c];
                }
                continue;
            }
            throw new Error('Missing current illustrated actor '+id);
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
        else {liveDocument.sprite.saveAs(LIVE.file);app.open(LIVE.file);console.log('LIVE_BOARD_COMPLETE '+LIVE.file);}
    }
}
