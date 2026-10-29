// All cropping, masks, nine-slice registration and RGBA edits run in LibreSprite.
function remap(value,from,to){
    for(var i=0;i<from.length-1;i++)if(value<from[i+1])return to[i]+(to[i+1]-to[i])*(value-from[i])/(from[i+1]-from[i]);
    return to[to.length-1]-0.001;
}
function hullY(x){
    var points=BUILD.hull;
    for(var i=0;i<points.length-1;i++)if(x<=points[i+1][0]){
        var a=points[i],b=points[i+1];return a[1]+(b[1]-a[1])*(x-a[0])/(b[0]-a[0]);
    }return points[points.length-1][1];
}
function skyColor(r,g,b,y){
    return y<=.68&&b>r+8&&g>r+3&&r>55&&g>60;
}
function onEvent(event){
    if(event!=='init')return;
    var reference=app.open(BUILD.input).sprite.layer(0).cel(0).image;
    var raw=reference.getImageData(),sw=reference.width,sh=reference.height,w=BUILD.size[0],h=BUILD.size[1];
    var output=new Uint8Array(w*h*4),mask=null,sky=null,solid=null;
    if(BUILD.kind==='background'&&!BUILD.alpha_input){
        // Grow sky through low-gradient neighbours, stopping at painted roof edges.
        // The envelope chooses top-edge seeds only; it never cuts straight roofs.
        sky=new Uint8Array(sw*sh);var queue=[],cursor=0;
        for(var seedX=0;seedX<sw;seedX+=4){
            var sp=seedX*4;
            if(hullY(seedX/(sw-1))>.045&&Math.max(raw[sp],raw[sp+1],raw[sp+2])>28){sky[seedX]=1;queue.push(seedX);}
        }
        while(cursor<queue.length){
            var at=queue[cursor++],x=at%sw,neighbors=[at-1,at+1,at-sw,at+sw],p=at*4;
            for(var j=0;j<4;j++){
                var next=neighbors[j];if(next<0||next>=sw*sh||sky[next])continue;
                if(j<2&&Math.abs(next%sw-x)>1)continue;
                var q=next*4,difference=Math.max(Math.abs(raw[p]-raw[q]),Math.abs(raw[p+1]-raw[q+1]),Math.abs(raw[p+2]-raw[q+2]));
                if(difference>22||!skyColor(raw[q],raw[q+1],raw[q+2],Math.floor(next/sw)/sh))continue;
                sky[next]=1;queue.push(next);
            }
        }
        // Detached cloud islands do not belong to the architecture plane.
        solid=new Uint8Array(sw*sh);queue=[];cursor=0;
        for(var seedX=0;seedX<sw;seedX++){
            var seed=(sh-1)*sw+seedX;if(!sky[seed]){solid[seed]=1;queue.push(seed);}
        }
        while(cursor<queue.length){
            var at=queue[cursor++],x=at%sw,neighbors=[at-1,at+1,at-sw,at+sw];
            for(var j=0;j<4;j++){
                var next=neighbors[j];if(next<0||next>=sw*sh||solid[next]||sky[next])continue;
                if(j<2&&Math.abs(next%sw-x)>1)continue;solid[next]=1;queue.push(next);
            }
        }
    }
    if(BUILD.kind==='frame'){
        mask=new Uint8Array(sw*sh);
        var first=BUILD.part.seed[1]*sw+BUILD.part.seed[0],queue=[first],cursor=0;mask[first]=1;
        while(cursor<queue.length){
            var at=queue[cursor++],x=at%sw,y=Math.floor(at/sw),neighbors=[at-1,at+1,at-sw,at+sw];
            for(var j=0;j<4;j++){
                var next=neighbors[j];if(next<0||next>=sw*sh||mask[next]||raw[next*4+3]<160)continue;
                if(j<2&&Math.abs(next%sw-x)>1)continue;mask[next]=1;queue.push(next);
            }
        }
    }
    for(var y=0;y<h;y++)for(var x=0;x<w;x++){
        var sx=(x+.5)*sw/w,sy=(y+.5)*sh/h,alpha=1;
        if(BUILD.kind==='frame'){
            var player=BUILD.name==='portador',b=BUILD.part.box;
            var dx=player?[0,32,368,400]:[0,80,916,996],dy=player?[0,14,28,42]:[0,44,62,88];
            if(x>=dx[1]&&x<dx[2]&&y>=dy[1]&&y<dy[2])continue;
            sx=remap(x,dx,[b[0],360,1175,b[2]]);sy=remap(y,dy,[b[1],BUILD.slot[0],BUILD.slot[1],b[3]]);
        }else if(BUILD.kind==='background'){
            alpha=Math.min(1,Math.min(x+1,w-x)/20);
        }
        sx=Math.max(0,Math.min(sw-1,Math.floor(sx)));sy=Math.max(0,Math.min(sh-1,Math.floor(sy)));
        var p=(sy*sw+sx)*4,q=(y*w+x)*4;
        if(solid&&!solid[sy*sw+sx])continue;
        if(mask&&!mask[sy*sw+sx])continue;
        if(raw[p+3]<100)continue;
        if(BUILD.kind==='skyline'){
            // Reject saturated blue/green matte fringes around generated transparency.
            if(raw[p+2]>raw[p]*1.8&&raw[p+2]>raw[p+1]*1.5)continue;
            alpha*=Math.min(1,Math.min(x+1,w-x)/18);
        }
        for(var c=0;c<3;c++)output[q+c]=raw[p+c];output[q+3]=Math.round(raw[p+3]*alpha);
    }
    var doc=app.open(BUILD.template);doc.sprite.layer(0).cel(0).image.putImageData(output);
    doc.sprite.saveAs(BUILD.ase);console.log('ENVIRONMENT_COMPLETE '+BUILD.name);
}
