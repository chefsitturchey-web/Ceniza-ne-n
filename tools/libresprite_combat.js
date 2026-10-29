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
function humanoid(body,gear,fx,entry,boss){
    var state=entry.state,t=entry.frame/Math.max(1,entry.count-1),phase=t*Math.PI*2;
    var east=entry.direction==='east'||entry.direction==='west',north=entry.direction==='north';
    var cx=boss?64:48,feet=boss?111:72, scale=boss?2:1;
    var walk=state==='walk'?Math.sin(phase):0, death=state==='death'?t:0;
    var prepare=state==='windup'?t:0,attack=state==='attack'?t:0;
    var lean=(state==='attack'?Math.sin(t*Math.PI)*3:0)+(state==='charge'?4:0)-(state==='windup'?2*t:0);
    var bob=state==='walk'?Math.abs(Math.sin(phase))*1.5:(state==='idle'?Math.sin(phase)*.5:0);
    if(state==='hurt')lean=-Math.sin(t*Math.PI)*3;
    if(state==='shoot')lean=-Math.sin(phase)*1.5;
    if(state==='exposed'&&!boss)lean=2;
    var hips=[cx+lean,feet-12*scale+death*7*scale], torso=[hips[0]+lean,feet-26*scale-bob+death*15*scale];
    if(state==='dodge'){hips[1]+=Math.sin(t*Math.PI)*5;torso[1]+=Math.sin(t*Math.PI)*11;torso[0]+=Math.sin(t*Math.PI)*5;}
    var head=[torso[0]+(east?2:0),torso[1]-9*scale+death*4*scale];
    var pal=boss?IVORY:METAL,cloth=boss?BURGUNDY:CLOTH;
    var capeWind=walk*2+Math.sin(phase)*.6;
    // Split cloak: separate hems, folds, stitching and worn corners follow the hips.
    poly(body,[[torso[0]-7*scale,torso[1]-4*scale],[torso[0]+7*scale,torso[1]-4*scale],[hips[0]+(11+capeWind)*scale,feet-(3-death*2)*scale],[hips[0]+5*scale,feet-5*scale],[hips[0]+1*scale,feet-2*scale],[hips[0]-2*scale,feet-6*scale],[hips[0]-(10-capeWind)*scale,feet-3*scale]],cloth,true);
    for(var s=-1;s<=1;s+=2){
        var hip=offset(hips,s*(east?2:4)*scale,0), knee=offset(hip,walk*s*3*scale,5*scale+Math.max(0,walk*s)*2*scale),foot=[cx+s*(east?2:5)*scale+walk*s*3*scale+death*s*5*scale,feet-Math.max(0,-walk*s)*3*scale];
        if(death>.4)knee[0]+=s*death*5*scale;
        arm(body,hip,knee,offset(foot,0,-2*scale),4*scale,pal);
        plate(body,foot[0]-3*scale,foot[1]-3*scale,7*scale,3*scale,pal);
        line(body,[foot[0]-2*scale,foot[1]],[foot[0]+3*scale,foot[1]],INK,scale);
    }
    // Breastplate with articulated waist, layered collar and shoulder armour.
    poly(body,[[torso[0]-7*scale,torso[1]-4*scale],[torso[0]+6*scale,torso[1]-5*scale],[torso[0]+(east?5:8)*scale,torso[1]+5*scale],[hips[0]+5*scale,hips[1]],[hips[0]-5*scale,hips[1]],[torso[0]-7*scale,torso[1]+5*scale]],pal,true);
    for(var r=0;r<3;r++)line(body,[hips[0]-5*scale,hips[1]-3*scale+r*2*scale],[hips[0]+5*scale,hips[1]-3*scale+r*2*scale],r===1?COPPER[2]:pal[0],scale);
    if(boss){
        for(var r=0;r<3;r++){var yy=torso[1]+r*4;poly(body,[[torso[0]-10,yy],[torso[0],yy+4],[torso[0]+10,yy],[torso[0]+8,yy+5],[torso[0],yy+8],[torso[0]-8,yy+5]],r%2?COPPER:IVORY,true);}
        crest(body,torso[0],torso[1]-1,1,GOLD);
        for(var s=-1;s<=1;s+=2){seam(body,[hips[0]+s*11,hips[1]+3],[hips[0]+s*16+capeWind,feet-9],COPPER);for(var r=0;r<3;r++)line(body,[hips[0]+s*(7+r*3),hips[1]+5],[hips[0]+s*(8+r*3),feet-10+r],BURGUNDY[0],1);}
    }else{
        recess(body,torso[0]-4,torso[1]+2,5,7,CYAN);
        for(var r=0;r<3;r++){point(body,torso[0]+4,torso[1]+2+r*2,RUST);point(body,torso[0]-6,torso[1]+5+r*2,HIGH);}
        seam(body,offset(torso,-6,-3),offset(hips,-6,5),CLOTH);
        line(body,offset(torso,-6,-3),offset(torso,5,-2),RUST,2);
        line(body,offset(torso,-5,-3),offset(torso,4,-3),GOLD,1);
    }
    if(!north){line(body,offset(torso,-3*scale,-2*scale),offset(torso,2*scale,5*scale),COPPER[2],scale);point(body,torso[0],torso[1]+1,CYAN);}
    else {plate(body,torso[0]-5*scale,torso[1]-2*scale,9*scale,13*scale,CLOTH);line(body,offset(torso,-2*scale,0),offset(torso,-2*scale,8*scale),COPPER[2],scale);}
    plate(body,head[0]-5*scale,head[1]-5*scale,10*scale,10*scale,pal);
    poly(body,[[head[0]-6*scale,head[1]+3*scale],[head[0]-6*scale,head[1]-4*scale],[head[0],head[1]-8*scale],[head[0]+5*scale,head[1]-4*scale],[head[0]+6*scale,head[1]+4*scale],[head[0]+3*scale,head[1]+5*scale],[head[0]+4*scale,head[1]-1*scale],[head[0]-3*scale,head[1]-1*scale],[head[0]-3*scale,head[1]+5*scale]],boss?IVORY:CLOTH,true);
    if(!north){line(body,offset(head,east?1:-3,-scale),offset(head,4*scale,-scale),INK,2*scale);line(body,offset(head,east?2:-2,0),offset(head,4*scale,0),CYAN,scale);}
    line(body,offset(head,-4*scale,2*scale),offset(head,-2*scale,4*scale),pal[0],scale);
    point(body,head[0]+3*scale,head[1]+3*scale,HIGH);
    if(boss){line(body,offset(head,0,-8*scale),offset(head,0,-2*scale),GOLD,scale);for(var s=-1;s<=1;s+=2)plate(gear,torso[0]+s*8*scale-4*scale,torso[1]-5*scale,9*scale,8*scale,IVORY);}
    var baseAngle=east?0:(north?-Math.PI/2:Math.PI/2), swing=state==='attack'?(-1.8+attack*3.4):(-.2-prepare*1.4);
    var shoulder=offset(torso,(east?4:7)*scale,0),elbow=offset(shoulder,(state==='windup'?-3:3)*scale,7*scale),hand=offset(elbow,(east?4:1)*scale,5*scale);
    if(state==='attack'||state==='windup'){hand=polar(shoulder,11*scale,baseAngle+swing*.65);elbow=polar(shoulder,6*scale,baseAngle+swing*.5+.4);}
    if(death>0){hand=offset(torso,15*scale,10*scale);elbow=offset(torso,10*scale,4*scale);}
    arm(gear,shoulder,elbow,hand,4*scale,pal);
    var swordAngle=baseAngle+(state==='attack'?swing:(state==='windup'?-1.4*prepare:.2));
    if(death>0)swordAngle=.2;
    if(state==='dodge')swordAngle=east?0:(north?-1:.5);
    blade(gear,fx,hand,swordAngle,boss?40:24,boss?3:2,boss?RED:CYAN,state==='attack'&&t>.1&&t<.8);
    var otherShoulder=offset(torso,-7*scale,0),otherHand=offset(torso,-10*scale,13*scale+walk*scale);
    otherHand[1]-=death*4*scale;
    arm(gear,otherShoulder,offset(torso,-9*scale,6*scale),otherHand,4*scale,pal);
    if(boss){
        var open=state==='exposed'?Math.sin(phase)*2+7:0;
        var shieldX=otherHand[0]-7*scale-open;
        poly(gear,[[shieldX,otherHand[1]-13*scale],[shieldX+13*scale,otherHand[1]-12*scale],[shieldX+15*scale,otherHand[1]+5*scale],[shieldX+7*scale,otherHand[1]+14*scale],[shieldX-2*scale,otherHand[1]+6*scale]],IVORY,true);
        line(gear,[shieldX+5*scale,otherHand[1]-10*scale],[shieldX+7*scale,otherHand[1]+10*scale],GOLD,scale);
        seam(gear,[shieldX+2,otherHand[1]-23],[shieldX+1,otherHand[1]+7],COPPER);
        crest(gear,shieldX+7*scale,otherHand[1]-2*scale,2,COPPER[1]);
        line(gear,[shieldX+5*scale,otherHand[1]+8*scale],[shieldX+8*scale,otherHand[1]+10*scale],GOLD,1);
        for(var r=0;r<4;r++)rivet(gear,shieldX+10*scale,otherHand[1]-8*scale+r*5*scale);
        if(state==='exposed')disk(fx,torso[0],torso[1]+4,4,5,[INK,GOLD,GOLD,WHITE]);
    } else {
        plate(gear,otherHand[0]-3,otherHand[1]-2,5,5,COPPER);
        line(body,offset(torso,-5,5),offset(torso,3,11),RUST,1);
        box(body,hips[0]-2,hips[1]-1,4,3,COPPER[2]);point(body,hips[0],hips[1],GOLD);
    }
    if(state==='hurt'){for(var k=0;k<4;k++)line(fx,offset(torso,k*3-5,-4),offset(torso,k*3-6,-8-k),rgba('ffce75',160),1);}
    if(state==='shoot'&&boss){var muzzle=polar(hand,10,baseAngle);bone(gear,hand,muzzle,6,METAL);line(gear,offset(hand,0,-3),offset(muzzle,0,-3),GOLD,1);if(entry.frame===1||entry.frame===3){for(var k=0;k<3;k++)line(fx,muzzle,polar(muzzle,7+k,baseAngle+(k-1)*.5),k===1?WHITE:GOLD,2);}}
}
function machine(body,gear,fx,e,kind){
    var t=e.frame/Math.max(1,e.count-1),phase=t*Math.PI*2,state=e.state,c=[64,64];
    var walk=state==='walk'||state==='charge'||state==='dodge'?Math.sin(phase):0,open=state==='exposed'?1:0,dead=state==='death'?t:0;
    var pulse=state==='idle'?Math.sin(phase):0,windup=state==='windup'?t:0,hit=state==='attack'?Math.sin(t*Math.PI):0;
    var pal=kind==='caldera'?COPPER:METAL,accent=kind==='caldera'?GOLD:(kind==='recaudador'?GOLD:CYAN);
    var count=kind==='coro'?6:4;
    // Individual limbs change knee and foot placement; no whole-image vibration.
    for(var leg=0;leg<count;leg++){
        var side=leg%2===0?-1:1,row=Math.floor(leg/2),hip=[64+side*20,48+row*15],elbow=[64+side*(33+walk*(row%2?1:-1)*3),52+row*17],foot=[64+side*(45+walk*side*2+dead*5),61+row*16-Math.max(0,walk*side)*5];
        if(kind==='recaudador'){plate(body,64+side*29-8,32,16,65,METAL);for(var r=0;r<10;r++)line(body,[64+side*29-6,35+r*6+Math.round(walk)],[64+side*29+6,35+r*6+Math.round(walk)],r%2?MID:INK,2);continue;}
        foot[1]+=dead*12;arm(body,hip,elbow,foot,7,pal);plate(body,foot[0]-6,foot[1]-3,12,8,pal);
    }
    var swell=kind==='coro'?pulse:0;
    poly(body,[[43,28+swell],[79,25+swell],[91,39],[90,85],[78,99],[48,100],[35,83],[35,43]],pal,true);
    plate(body,42,35,42,52,pal);
    for(var s=-1;s<=1;s+=2){recess(body,64+s*22-4,48,8,21,pal[3]);seam(body,[64+s*18,36],[64+s*18,87],pal);}
    plate(body,54,27,20,10,METAL);recess(body,58,30,12,4,accent);
    for(var side=-1;side<=1;side+=2){
        plate(body,64+side*22-6,42,12,39,pal);
        for(var r=0;r<5;r++){line(body,[64+side*22-4,48+r*6],[64+side*22+4,48+r*6],INK,1);point(body,64+side*22-3,47+r*6,HIGH);}
        var shoulder=[64+side*24,48],elbow=[64+side*(37+windup*3),63-windup*12],hand=[64+side*(40+hit*10),84-windup*17+hit*9];
        if(state==='hurt'){elbow[1]-=Math.sin(phase)*3;hand[0]+=Math.sin(phase)*3;}
        if(dead){elbow[1]+=dead*20;hand[0]+=side*dead*5;hand[1]+=dead*11;}
        arm(gear,shoulder,elbow,hand,8,pal);
        var jaw=state==='attack'?hit*5:(state==='windup'?4:1);
        bone(gear,hand,offset(hand,-4-jaw,12),4,pal);bone(gear,hand,offset(hand,4+jaw,12),4,pal);
        line(gear,offset(hand,-4-jaw,12),offset(hand,-2,15),HIGH,2);line(gear,offset(hand,4+jaw,12),offset(hand,2,15),HIGH,2);
    }
    if(kind==='caldera'){
        for(var s=-1;s<=1;s+=2){plate(body,64+s*18-6,11,12,35,COPPER);for(var r=0;r<4;r++)line(body,[64+s*18-5,17+r*6],[64+s*18+5,17+r*6],INK,2);}
        disk(gear,64,58,18,22,COPPER);
        for(var r=0;r<7;r++)line(gear,[52,43+r*5],[76,43+r*5],r%2?GOLD:INK,2);
        for(var s=-1;s<=1;s+=2)plate(gear,64+s*(8+open*15)-8,36,16,47,METAL);
        for(var s=-1;s<=1;s+=2){var door=64+s*(8+open*15)-8;recess(gear,door+4,44,5,25,GOLD);line(gear,[door+4,73],[door+11,73],RUST,2);for(var r=0;r<3;r++)rivet(gear,door+11,43+r*13);}
        disk(gear,64,25,7,7,METAL);line(gear,[64,25],polar([64,25],5,-1+windup+Math.sin(phase)*.5),RED,1);
        for(var s=-1;s<=1;s+=2){disk(gear,64+s*14,80,5,5,COPPER);for(var r=0;r<3;r++)line(gear,[64+s*14,80],polar([64+s*14,80],4,phase+r*Math.PI*2/3),HIGH,1);}
    }else if(kind==='coro'){
        for(var s=-1;s<=1;s+=2){arm(gear,[64+s*15,37],[64+s*28,24+Math.sin(phase+s)*3],[64+s*39,16+Math.sin(phase+s)*4],4,METAL);disk(gear,64+s*39,16+Math.sin(phase+s)*4,8,6,COPPER);}
        disk(gear,64,59,17,24,METAL);arc(gear,[64,59],13,phase,phase+4.8,CYAN,2);
        for(var r=0;r<8;r++){var at=polar([64,59],20,r*Math.PI/4);rivet(gear,at[0],at[1]);}
        disk(gear,64,59,open?9:5,open?12:7,[INK,RED,CYAN,WHITE]);
        for(var r=0;r<5;r++)line(body,[47,78+r*3],[81,78+r*3],r%2?COPPER[2]:INK,1);
    }else{
        plate(gear,48,39,32,38,METAL);disk(gear,64,57,10,13,[INK,RUST,GOLD,WHITE]);
        for(var s=-1;s<=1;s+=2)plate(gear,64+s*(7+open*12)-7,37,14,40,METAL);
        for(var s=-1;s<=1;s+=2){var xx=64+s*(7+open*12);recess(gear,xx-3,43,6,22,GOLD);crest(gear,xx,71,1,RUST);}
        var shieldY=90+open*12;
        poly(gear,[[24,shieldY-6],[104,shieldY-6],[110,shieldY+7],[101,shieldY+13],[27,shieldY+13],[18,shieldY+6]],METAL,true);
        for(var r=0;r<9;r++)line(gear,[28+r*8,shieldY-2],[24+r*8,shieldY+6],r%2?GOLD:RUST,2);
        disk(gear,64,22,9,9,METAL);for(var r=0;r<7;r++)line(gear,[64,22],polar([64,22],7,phase+r*Math.PI*2/7),HIGH,1);
    }
    if(state==='shoot'){
        plate(gear,55,89-t*3,18,14,METAL);box(gear,59,99-t*3,10,4,INK);
        if(e.frame===1||e.frame===3)poly(fx,[[58,104],[62,118],[66,109],[71,119],[72,104]],[RUST,GOLD,GOLD,WHITE],false);
    }
    if(open)arc(fx,c,20+Math.sin(phase)*2,0,Math.PI*2,rgba('ffce75',180),1);
    if(kind==='caldera'&&(open||state==='windup'||state==='attack'))for(var r=0;r<5;r++){var age=(e.frame*3+r*5)%22;disk(fx,46+Math.sin(age)*3,30-age,3+Math.floor(age/8),2,[rgba('536d7d',70),rgba('8299a8',130),rgba('8299a8',130),rgba('c4d2ce',100)]);}
    if(dead>0){for(var r=0;r<12;r++){var angle=r*2.4;var at=polar(c,dead*(15+r*2),angle);box(fx,at[0],at[1],2,2,r%2?GOLD:RED);}}
}
function mother(body,gear,fx,e){
    var t=e.frame/Math.max(1,e.count-1),phase=t*Math.PI*2,open=e.state==='exposed'?1:0,death=e.state==='death'?t:0;
    var sway=Math.sin(phase)*2,cy=60+sway+death*8;
    // Segmented halo and six individually bent cable-arms, drawn behind the body.
    for(var r=0;r<12;r++){var a=-Math.PI+r*Math.PI/11,at=[64+Math.cos(a)*46,53+Math.sin(a)*40];var drift=open?Math.sin(phase+r)*4:0;plate(body,at[0]-5+drift,at[1]-9,10,19,r%3?METAL:COPPER);point(body,at[0]+drift,at[1]-4,CYAN);}
    for(var r=0;r<6;r++){var side=r%2?-1:1,row=Math.floor(r/2),shoulder=[64+side*13,cy+row*8],elbow=[64+side*(28+Math.sin(phase+r)*3),cy+10+row*7],hand=[64+side*(48-open*7),cy+2+row*15+Math.sin(phase+r)*4];if(e.state==='attack'||e.state==='shoot')hand[1]+=Math.sin(t*Math.PI)*10;arm(gear,shoulder,elbow,hand,5,METAL);bone(gear,hand,offset(hand,side*4,9),3,COPPER);point(gear,hand[0],hand[1],CYAN);}
    poly(body,[[51,cy-15],[77,cy-15],[86,cy+30],[79,cy+50],[69,cy+42],[64,cy+55],[57,cy+43],[47,cy+50],[42,cy+29]],BURGUNDY,true);
    plate(body,49,cy-13,30,44,METAL);
    for(var r=0;r<4;r++){var yy=cy-8+r*9;line(body,[51,yy],[58,yy+5],COPPER[2],2);line(body,[77,yy],[70,yy+5],COPPER[2],2);rivet(body,51,yy);rivet(body,77,yy);}
    for(var side=-1;side<=1;side+=2){for(var r=0;r<4;r++)bone(body,[64+side*12,cy+r*6],[64+side*(16+open*5),cy+r*6+9],3,COPPER);}
    disk(gear,64,cy+9,7+open*3,13+open*2,[INK,STEEL,CYAN,WHITE]);
    for(var r=0;r<5;r++){var at=polar([64,cy+9],14+open*4,phase+r*1.256);point(fx,at[0],at[1],CYAN);}
    var look=e.direction==='east'?3:(e.direction==='west'?-3:0);
    plate(body,56+look,cy-34,16,20,IVORY);poly(body,[[54+look,cy-34],[58+look,cy-44],[64+look,cy-37],[70+look,cy-44],[75+look,cy-34]],COPPER,true);
    if(e.direction!=='north'){line(body,[58+look,cy-25],[61+look,cy-25],RED,2);line(body,[67+look,cy-25],[70+look,cy-25],RED,2);point(body,64+look,cy-17,INK);}
    else {plate(body,57,cy-31,14,15,METAL);line(body,[64,cy-30],[64,cy-17],COPPER[2],2);}
    for(var side=-1;side<=1;side+=2){line(body,[64+side*12,cy-34],[64+side*23,cy+29],INK,5);line(body,[64+side*12,cy-34],[64+side*23,cy+29],COPPER[1],2);}
    crest(body,64,cy+39,1,GOLD);
}
function transformed(data,direction,robot){
    if(direction==='south')return data;
    if(!robot&&direction!=='west')return data;
    var out=new Uint8Array(data.length);
    for(var y=0;y<N;y++)for(var x=0;x<N;x++){
        var sx=x,sy=y;
        if(!robot)sx=N-1-x;
        else if(direction==='north'){sx=N-1-x;sy=N-1-y;}
        else if(direction==='east'){sx=y;sy=N-1-x;}
        else {sx=N-1-y;sy=x;}
        var a=(sy*N+sx)*4,b=(y*N+x)*4;for(var c=0;c<4;c++)out[b+c]=data[a+c];
    }
    return out;
}
function build(){
    for(var a=0;a<BUILD.actors.length;a++){
        var actor=BUILD.actors[a];N=actor==='portador'?96:(actor==='prefecto'?160:128);ORIGIN=actor==='prefecto'?16:0;
        var doc=app.open(BUILD.work+'/'+actor+'-blank.ase');
        for(var f=0;f<BUILD.entries.length;f++){
            var entry=BUILD.entries[f],body=new Uint8Array(N*N*4),gear=new Uint8Array(N*N*4),fx=new Uint8Array(N*N*4);
            if(actor==='portador'||actor==='prefecto')humanoid(body,gear,fx,entry,actor==='prefecto');
            else if(actor==='madre')mother(body,gear,fx,entry);
            else machine(body,gear,fx,entry,actor);
            var robot=actor!=='portador'&&actor!=='prefecto'&&actor!=='madre';
            doc.sprite.layer(0).cel(f).image.putImageData(transformed(body,entry.direction,robot));
            doc.sprite.layer(1).cel(f).image.putImageData(transformed(gear,entry.direction,robot));
            doc.sprite.layer(2).cel(f).image.putImageData(transformed(fx,entry.direction,robot));
        }
        doc.sprite.saveAs(BUILD.output+'/sources/'+actor+'.ase');
        console.log('Native pixels completed: '+actor);
    }
}
function onEvent(event){if(event==='init')build();}
