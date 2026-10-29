// Native LibreSprite ES5. All pixel drawing and full pose rendering happen here.
// No raster source images: silhouettes, armour, weapons and effects are drawn in cels.
var N = 128;
var ORIGIN = 0;
function rgba(hex, alpha) { return [parseInt(hex.substr(0,2),16), parseInt(hex.substr(2,2),16), parseInt(hex.substr(4,2),16), alpha === undefined ? 255 : alpha]; }
var INK=rgba('0b1322'), DEEP=rgba('182639'), STEEL=rgba('304356'), MID=rgba('536d7d'), HIGH=rgba('8299a8'), WHITE=rgba('c4d2ce');
var CYAN=rgba('47dacb'), GOLD=rgba('ffce75'), RUST=rgba('b87949'), RED=rgba('dd6482');
var METAL=[DEEP,STEEL,MID,HIGH,WHITE], IVORY=[rgba('34333a'),rgba('65635c'),rgba('a8a397'),rgba('d5ccae'),rgba('f0e4c6')];
var COPPER=[rgba('30262b'),rgba('704c43'),rgba('ad744f'),rgba('d1a075'),GOLD];
var CLOTH=[rgba('131d2b'),rgba('243344'),rgba('364c5b'),rgba('58717b'),HIGH];
var BURGUNDY=[rgba('271b2b'),rgba('4d2536'),rgba('7f3e49'),rgba('b5655e'),rgba('d19b7e')];
function point(out,x,y,c) {
    x=Math.round(x)+ORIGIN; y=Math.round(y)+ORIGIN;
    if(x<0||y<0||x>=N||y>=N)return;
    var p=(y*N+x)*4;
    for(var k=0;k<4;k++)out[p+k]=c[k];
}
function box(out,x,y,w,h,c){for(var j=0;j<h;j++)for(var i=0;i<w;i++)point(out,x+i,y+j,c);}
function line(out,a,b,c,w){var steps=Math.max(1,Math.ceil(Math.max(Math.abs(b[0]-a[0]),Math.abs(b[1]-a[1]))));w=w||1;for(var i=0;i<=steps;i++)box(out,a[0]+(b[0]-a[0])*i/steps-w/2,a[1]+(b[1]-a[1])*i/steps-w/2,w,w,c);}
function disk(out,x,y,rx,ry,pal){for(var j=-ry;j<=ry;j++)for(var i=-rx;i<=rx;i++){var d=i*i/(rx*rx)+j*j/(ry*ry);if(d>1)continue;var shade=d>0.75?0:(i/rx+j/ry<-.3?3:1);point(out,x+i,y+j,pal[Math.min(shade,pal.length-1)]);}point(out,x-rx*.25,y-ry*.4,pal[pal.length-1]);}
function poly(out,pts,pal,detail){
    var top=N,bottom=0,left=N,right=0;
    for(var p=0;p<pts.length;p++){top=Math.min(top,pts[p][1]);bottom=Math.max(bottom,pts[p][1]);left=Math.min(left,pts[p][0]);right=Math.max(right,pts[p][0]);}
    for(var y=Math.ceil(top);y<=Math.floor(bottom);y++){
        var cuts=[];
        for(var i=0;i<pts.length;i++){var a=pts[i],b=pts[(i+1)%pts.length];if((a[1]<=y&&b[1]>y)||(b[1]<=y&&a[1]>y))cuts.push(a[0]+(y-a[1])*(b[0]-a[0])/(b[1]-a[1]));}
        cuts.sort(function(a,b){return a-b;});
        for(var i=0;i+1<cuts.length;i+=2)for(var x=Math.ceil(cuts[i]);x<=Math.floor(cuts[i+1]);x++){
            var shade=(x-left)/(right-left+1)+(y-top)/(bottom-top+1), idx=shade<.65?3:(shade<1.2?2:1);
            if(detail){var h=((x-Math.floor(left))*37+(y-Math.floor(top))*71)%97;if(h<4)idx=Math.max(0,idx-1);if(h===7)idx=Math.min(4,idx+1);}
            point(out,x,y,pal[Math.min(idx,pal.length-1)]);
        }
    }
    for(var i=0;i<pts.length;i++){var a=pts[i],b=pts[(i+1)%pts.length];line(out,a,b,INK,1);if(b[0]>a[0]&&b[1]<=a[1]+3)line(out,[a[0]+1,a[1]+1],[b[0]-1,b[1]+1],pal[3],1);}
}
function plate(out,x,y,w,h,pal){poly(out,[[x+3,y],[x+w-3,y],[x+w,y+3],[x+w-1,y+h-3],[x+w-4,y+h],[x+2,y+h],[x,y+h-3],[x,y+3]],pal,true);if(w>12&&h>12){rivet(out,x+4,y+4);rivet(out,x+w-4,y+h-4);line(out,[x+5,y+h-5],[x+w-7,y+h-6],pal[0],1);}}
function rivet(out,x,y){point(out,x,y,INK);point(out,x-1,y-1,HIGH);}
function recess(out,x,y,w,h,accent){box(out,x-1,y-1,w+2,h+2,INK);box(out,x,y,w,h,DEEP);line(out,[x,y],[x+w-1,y],HIGH,1);for(var r=2;r<h;r+=3){line(out,[x+1,y+r],[x+w-2,y+r],STEEL,1);point(out,x+1,y+r-1,accent);}}
function crest(out,x,y,s,accent){line(out,[x,y-4*s],[x-3*s,y],accent,s);line(out,[x-3*s,y],[x,y+5*s],accent,s);line(out,[x,y+5*s],[x+3*s,y],accent,s);line(out,[x+3*s,y],[x,y-4*s],accent,s);line(out,[x,y-2*s],[x,y+3*s],accent,s);point(out,x,y,WHITE);}
function seam(out,a,b,pal){line(out,a,b,INK,2);line(out,offset(a,1,0),offset(b,1,0),pal[3],1);var length=Math.max(Math.abs(b[0]-a[0]),Math.abs(b[1]-a[1]));for(var i=4;i<length;i+=6){var t=i/length;rivet(out,a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t);}}
function add(a,b){return[a[0]+b[0],a[1]+b[1]];}
function offset(a,x,y){return[a[0]+x,a[1]+y];}
function polar(a,len,angle){return[a[0]+Math.cos(angle)*len,a[1]+Math.sin(angle)*len];}
function bone(out,a,b,width,pal){var dx=b[0]-a[0],dy=b[1]-a[1],d=Math.sqrt(dx*dx+dy*dy)||1,nx=-dy/d*width/2,ny=dx/d*width/2;poly(out,[[a[0]+nx,a[1]+ny],[b[0]+nx*.8,b[1]+ny*.8],[b[0]-nx*.8,b[1]-ny*.8],[a[0]-nx,a[1]-ny]],pal,true);}
function arm(out,a,b,c,width,pal){bone(out,a,b,width,pal);disk(out,b[0],b[1],width/2+1,width/2+1,METAL);bone(out,b,c,width*.8,pal);disk(out,c[0],c[1],width*.45,width*.4,pal);}
function arc(out,center,r,start,end,color,width){var last=polar(center,r,start);for(var s=1;s<=24;s++){var next=polar(center,r,start+(end-start)*s/24);line(out,last,next,color,width||1);last=next;}}
function blade(out,fx,hand,angle,length,width,accent,trail){
    var hilt=polar(hand,-5,angle), guard=polar(hand,3,angle),tip=polar(hand,length,angle),base=polar(hand,7,angle),side=[-Math.sin(angle)*width,Math.cos(angle)*width];
    line(out,hilt,base,COPPER[1],3);
    poly(out,[[base[0]+side[0],base[1]+side[1]],[tip[0],tip[1]],[base[0]-side[0],base[1]-side[1]]],METAL,true);
    line(out,base,tip,WHITE,1);line(out,[base[0]+side[0],base[1]+side[1]],tip,accent,1);
    line(out,polar(guard,width+3,angle+Math.PI/2),polar(guard,width+3,angle-Math.PI/2),GOLD,2);
    disk(out,hand[0],hand[1],2,2,COPPER);
    if(trail){for(var k=0;k<3;k++)arc(fx,hand,length-2-k*2,angle-.7,angle-.12,rgba(k===0?'d8fff2':'47dacb',170-k*45),1);}
}
function build(){
    for(var a=0;a<BUILD.actors.length;a++){
        var actor=BUILD.actors[a];N=actor.indexOf('portador')===0?96:(actor==='prefecto'?160:128);ORIGIN=actor==='prefecto'?16:0;
        var doc=app.open(BUILD.work+'/'+actor+'-blank.ase');
        for(var f=0;f<BUILD.entries.length;f++){
            var entry=BUILD.entries[f],body=new Uint8Array(N*N*4),gear=new Uint8Array(N*N*4),fx=new Uint8Array(N*N*4);
            renderProjection(body,gear,fx,entry,actor);
            if(f===0){
                var bounds=[N,N,0,0];
                for(var yy=0;yy<N;yy++)for(var xx=0;xx<N;xx++)if(body[(yy*N+xx)*4+3]){
                    bounds[0]=Math.min(bounds[0],xx);bounds[1]=Math.min(bounds[1],yy);bounds[2]=Math.max(bounds[2],xx+1);bounds[3]=Math.max(bounds[3],yy+1);
                }
                console.log('Native body bounds: '+actor+' '+JSON.stringify(bounds));
            }
            if(entry.state==='idle'&&entry.frame===0)console.log('Native orientation: '+actor+' '+entry.direction+' '+JSON.stringify({head:LAST_HEAD,feet:LAST_FEET,front:LAST_FRONT}));
            doc.sprite.layer(0).cel(f).image.putImageData(body);
            doc.sprite.layer(1).cel(f).image.putImageData(gear);
            doc.sprite.layer(2).cel(f).image.putImageData(fx);
        }
        doc.sprite.saveAs(BUILD.output+'/sources/'+actor+'.ase');
        console.log('Native pixels completed: '+actor);
    }
}
function onEvent(event){if(event==='init')build();}
