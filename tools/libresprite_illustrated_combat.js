// Native LibreSprite ES5. Painted poses stay complete and independently editable.
var SIZE=BUILD.size,ANCHOR=BUILD.anchor,HEIGHT=BUILD.height;
var reference,raw,sourceScale,sources={},activeMask=null,activeRect=null;
function occupied(x,y){
    if(raw[(y*reference.width+x)*4+3]<200)return false;
    return !activeMask||activeMask[(y-activeRect[1])*(activeRect[2]-activeRect[0])+x-activeRect[0]]===1;
}
function contour(sheet,row,pose){
    if(!sheet.measurements.seeds)return null;
    var key=row+':'+pose;if(sheet.masks[key])return sheet.masks[key];
    var rect=sheet.measurements.rows[row][pose],seed=sheet.measurements.seeds[row][pose];
    var w=rect[2]-rect[0],h=rect[3]-rect[1],mask=new Uint8Array(w*h),first=(seed[1]-rect[1])*w+seed[0]-rect[0],queue=[first],cursor=0;mask[first]=1;
    while(cursor<queue.length){
        var at=queue[cursor++],x=at%w,y=Math.floor(at/w);
        for(var oy=-1;oy<=1;oy++)for(var ox=-1;ox<=1;ox++){
            var xx=x+ox,yy=y+oy,next=yy*w+xx;
            if(xx<0||yy<0||xx>=w||yy>=h||mask[next])continue;
            if(sheet.pixels[((yy+rect[1])*sheet.width+xx+rect[0])*4+3]<200)continue;
            mask[next]=1;queue.push(next);
        }
    }
    sheet.masks[key]=mask;return mask;
}
function pixel(out,x,y,color){
    x=Math.round(x);y=Math.round(y);if(x<0||y<0||x>=SIZE||y>=SIZE)return;
    var p=(y*SIZE+x)*4;for(var c=0;c<4;c++)out[p+c]=color[c];
}
function bodyBounds(data){
    var b=[SIZE,SIZE,0,0];
    for(var y=0;y<SIZE;y++)for(var x=0;x<SIZE;x++)if(data[(y*SIZE+x)*4+3]>96){
        b[0]=Math.min(b[0],x);b[1]=Math.min(b[1],y);b[2]=Math.max(b[2],x+1);b[3]=Math.max(b[3],y+1);
    }return b;
}
function clearSpecks(data){
    var seen=new Uint8Array(SIZE*SIZE),components=[],largest=0;
    for(var at=0;at<SIZE*SIZE;at++){
        if(seen[at]||data[at*4+3]<96)continue;
        var queue=[at],cursor=0,box=[SIZE,SIZE,0,0];seen[at]=1;
        while(cursor<queue.length){
            var p=queue[cursor++],x=p%SIZE,y=Math.floor(p/SIZE);
            box[0]=Math.min(box[0],x);box[1]=Math.min(box[1],y);box[2]=Math.max(box[2],x);box[3]=Math.max(box[3],y);
            for(var oy=-1;oy<=1;oy++)for(var ox=-1;ox<=1;ox++){
                var xx=x+ox,yy=y+oy,q=yy*SIZE+xx;
                if(xx<0||yy<0||xx>=SIZE||yy>=SIZE||seen[q]||data[q*4+3]<96)continue;
                seen[q]=1;queue.push(q);
            }
        }
        components.push({pixels:queue,box:box});if(queue.length>components[largest].pixels.length)largest=components.length-1;
    }
    if(!components.length)return;
    var main=components[largest].box;
    for(var i=0;i<components.length;i++){
        var part=components[i],b=part.box;
        var far=b[2]<main[0]-5||b[0]>main[2]+5||b[3]<main[1]-5||b[1]>main[3]+5;
        if(part.pixels.length<=16&&far)for(var j=0;j<part.pixels.length;j++)data[part.pixels[j]*4+3]=0;
    }
}
function support(rect,pose,attackRegistration){
    if(pose===11)return [(rect[0]+rect[2])/2,rect[3]];
    var samples=[],bottom=rect[3],start;
    // The median of the supporting boots/feet avoids centring on a long sword.
    // Non-humanoid chassis use their solid central mass instead of forward claws.
    var mechanical=['recaudador','caldera','coro'].indexOf(BUILD.actor)>=0;
    if(!mechanical&&attackRegistration){
        // A forward-pointing blade may extend below the boots in a front view.
        // Register on a sufficiently wide dark boot row, not the sword tip.
        var minimum=Math.max(8,Math.min((rect[2]-rect[0])*.08,HEIGHT/sourceScale*.11));
        for(var yy=rect[3]-1;yy>rect[1]+(rect[3]-rect[1])*.55;yy--){
            var count=0;
            for(var xx=rect[0];xx<rect[2];xx++){var a=(yy*reference.width+xx)*4;if(occupied(xx,yy)&&raw[a]<105&&raw[a+1]<105&&raw[a+2]<115)count++;}
            if(count>=minimum){bottom=yy+1;break;}
        }
    }
    start=Math.floor(bottom-(rect[3]-rect[1])*.16);
    if(mechanical)start=Math.floor(rect[1]+(rect[3]-rect[1])*.3);
    var end=mechanical?Math.floor(rect[1]+(rect[3]-rect[1])*.7):bottom;
    for(var y=start;y<end;y++)for(var x=rect[0];x<rect[2];x++)if(occupied(x,y))samples.push(x);
    samples.sort(function(a,b){return a-b;});
    return [samples.length?samples[Math.floor(samples.length/2)]:(rect[0]+rect[2])/2,bottom];
}
function drawPose(body,fx,e){
    var sheet=sources[e.sheet||'base'];reference=sheet;raw=sheet.pixels;sourceScale=sheet.scale;
    var row=['south','east','north','west'].indexOf(e.direction),pose=e.pose;
    var hero=BUILD.actor.indexOf('portador')===0;
    var mechanical=['recaudador','caldera','coro'].indexOf(BUILD.actor)>=0;
    // Reject the generated side-firing smear: it turns toward screen-right even
    // in the front/back rows. Keep the correctly oriented braced/follow-through
    // mechanism and use the encounter's real directional projectile/telegraph.
    if(mechanical&&e.state==='attack')pose=[6,8,8,8,5,5,0,0][e.frame];
    if(mechanical&&e.state==='shoot')pose=[0,5,6,8,5,0][e.frame];
    if(e.state==='exposed'&&!hero)pose=9;
    var rect=sheet.measurements.rows[row][pose];activeRect=rect;activeMask=contour(sheet,row,pose);
    var root=support(rect,pose,e.state==='attack'||e.state==='shoot'||e.sheet==='attack');
    var breathe=(e.state==='idle'||e.state==='exposed')?[0,0,1,2,1,0][e.frame%6]:0;
    var base=Math.floor(ANCHOR[1]-HEIGHT*.55),radius=HEIGHT*.27;
    for(var y=1;y<SIZE-1;y++)for(var x=1;x<SIZE-1;x++){
        var chest=Math.max(0,1-Math.abs((y-base)/radius));
        var sy=Math.floor((y+Math.round(breathe*chest)-ANCHOR[1])/sourceScale+root[1]);
        var sx=Math.floor((x-ANCHOR[0])/sourceScale+root[0]);
        if(sx<rect[0]||sx>=rect[2]||sy<rect[1]||sy>=rect[3])continue;
        var p=(sy*reference.width+sx)*4;if(!occupied(sx,sy))continue;
        var color=[raw[p],raw[p+1],raw[p+2],255];
        if(e.state==='hurt'&&e.frame===1)for(var c=0;c<3;c++)color[c]=Math.round(color[c]*.75+255*.25);
        if(e.state==='exposed'&&color[1]>color[0]*1.2&&color[2]>color[0]*1.2){
            var power=1.1+Math.sin(e.frame*Math.PI/3)*.15;
            color[1]=Math.min(255,Math.round(color[1]*power));color[2]=Math.min(255,Math.round(color[2]*power));
        }
        pixel(body,x,y,color);
    }
    // Secondary effects live on their own editable layer; they never replace a weapon.
    if(e.state==='walk'||e.state==='charge'){
        if(e.frame===1||e.frame===5){
            var step=e.frame===1?-1:1;
            pixel(fx,ANCHOR[0]+step*8,ANCHOR[1]-2,[130,153,168,110]);
            pixel(fx,ANCHOR[0]+step*10,ANCHOR[1]-3,[130,153,168,70]);
        }
    }
    if(e.state==='exposed'&&hero){
        var at=ANCHOR[1]-HEIGHT*.78;
        pixel(fx,ANCHOR[0]+12,at+e.frame%3,[130,204,219,180]);
    }
}
function assemble(){
    for(var key in BUILD.sheets){
        var spec=BUILD.sheets[key],image=app.open(spec.reference).sprite.layer(0).cel(0).image,maxHeight=0;
        for(var row=0;row<4;row++){var b=spec.measurements.rows[row][spec.reference_pose];maxHeight=Math.max(maxHeight,b[3]-b[1]);}
        sources[key]={width:image.width,height:image.height,pixels:image.getImageData(),measurements:spec.measurements,scale:HEIGHT*spec.height_factor/maxHeight,masks:{}};
    }
    var doc=app.open(BUILD.work+'/'+BUILD.actor+'-painted.ase');
    for(var f=0;f<BUILD.entries.length;f++){
        var body=new Uint8Array(SIZE*SIZE*4),fx=new Uint8Array(SIZE*SIZE*4);
        drawPose(body,fx,BUILD.entries[f]);
        clearSpecks(body);
        var bounds=bodyBounds(body);
        if(bounds[0]<2||bounds[1]<2||bounds[2]>SIZE-2||bounds[3]>SIZE-2)throw new Error('Clipped pose '+BUILD.actor+' '+f);
        doc.sprite.layer(0).cel(f).image.putImageData(body);
        doc.sprite.layer(2).cel(f).image.putImageData(fx);
        if(f===0)console.log('PAINTED_BODY '+JSON.stringify(bounds));
    }
    doc.sprite.saveAs(BUILD.output+'/sources/'+BUILD.actor+'.ase');
    console.log('PAINTED_COMPLETE '+BUILD.actor);
}
function onEvent(event){if(event==='init')assemble();}
