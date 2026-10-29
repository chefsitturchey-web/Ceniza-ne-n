// Camera-correct artwork. Helpers and pixel buffers are owned by LibreSprite.
var SKIN=[rgba('513b32'),rgba('8c5d43'),rgba('bd865f'),rgba('dcaa7d'),rgba('f2c99d')];
var HAIR=[rgba('090d13'),rgba('151c25'),rgba('26313d'),rgba('3d4c59'),rgba('5d6972')];
var COAT=[rgba('241d1b'),rgba('49372c'),rgba('71523c'),rgba('97724b'),rgba('ba9465')];
var SCARF=[rgba('10151d'),rgba('242c36'),rgba('39424c'),rgba('59636b'),rgba('7a8285')];
function ellipseRing(out,c,rx,ry,thick,pal){
    for(var y=-Math.ceil(ry);y<=ry;y++)for(var x=-Math.ceil(rx);x<=rx;x++){
        var d=x*x/(rx*rx)+y*y/(ry*ry);
        if(d>1||d<Math.pow(1-thick/Math.min(rx,ry),2))continue;
        var light=-x/rx*.5-y/ry*.7;
        point(out,c[0]+x,c[1]+y,pal[light>.55?4:(light>.1?3:(light>-.5?2:1))]);
    }
}
function dome(out,c,rx,ry,pal){
    for(var y=-Math.ceil(ry);y<=ry;y++)for(var x=-Math.ceil(rx);x<=rx;x++){
        var d=x*x/(rx*rx)+y*y/(ry*ry);if(d>1)continue;
        var light=-x/rx*.5-y/ry*.7+Math.sqrt(1-d)*.4;
        point(out,c[0]+x,c[1]+y,d>.88?pal[0]:pal[light>.65?4:(light>.2?3:(light>-.2?2:1))]);
    }
}
function cable(out,a,b,c,pal,width){
    var last=a;
    for(var i=1;i<=20;i++){var t=i/20,u=1-t,next=[u*u*a[0]+2*u*t*b[0]+t*t*c[0],u*u*a[1]+2*u*t*b[1]+t*t*c[1]];line(out,last,next,INK,width+2);line(out,last,next,pal[1],width);line(out,offset(last,-1,-1),offset(next,-1,-1),pal[3],1);last=next;}
}
function gridVent(out,x,y,w,h,accent){
    poly(out,[[x+2,y],[x+w-2,y],[x+w,y+2],[x+w,y+h-2],[x+w-2,y+h],[x+2,y+h],[x,y+h-2],[x,y+2]],METAL,true);
    box(out,x+3,y+3,w-5,h-5,INK);
    for(var yy=y+4;yy<y+h-2;yy+=3){line(out,[x+4,yy],[x+w-3,yy],MID,1);point(out,x+4,yy-1,accent);}
    rivet(out,x+2,y+2);rivet(out,x+w-2,y+h-2);
}
function pipeJoint(out,at,r,pal){dome(out,at,r,r,pal);ellipseRing(out,at,r,r,1,METAL);point(out,at[0]-1,at[1]-1,WHITE);}
function hairHead(out,c,north,east,overhead){
    var rx=overhead?6:4,ry=overhead?5:5;
    dome(out,c,rx,ry,SKIN);
    if(north){dome(out,offset(c,0,-1),rx+1,ry+1,HAIR);for(var i=-3;i<4;i+=2)line(out,offset(c,i,-3),offset(c,i-1,3),HAIR[2],1);return;}
    var pts=overhead?[[c[0]-7,c[1]-2],[c[0]-6,c[1]-6],[c[0]-2,c[1]-8],[c[0]-3,c[1]-6],[c[0]+2,c[1]-7],[c[0]+6,c[1]-5],[c[0]+7,c[1]],[c[0]+4,c[1]-2],[c[0]+2,c[1]+3],[c[0]+1,c[1]-2],[c[0]-2,c[1]+1],[c[0]-2,c[1]-2],[c[0]-5,c[1]+3],[c[0]-5,c[1]-1]]:
      [[c[0]-5,c[1]],[c[0]-6,c[1]-3],[c[0]-4,c[1]-6],[c[0],c[1]-7],[c[0]-1,c[1]-5],[c[0]+4,c[1]-5],[c[0]+5,c[1]-1],[c[0]+3,c[1]-2],[c[0]+1,c[1]+2],[c[0]+1,c[1]-2],[c[0]-2,c[1]],[c[0]-2,c[1]-2],[c[0]-4,c[1]+2]];
    poly(out,pts,HAIR,false);
    line(out,offset(c,-3,-4),offset(c,0,-5),HAIR[3],1);line(out,offset(c,1,-4),offset(c,3,-3),HAIR[2],1);
    if(!overhead){point(out,c[0]+(east?3:-1),c[1]+1,INK);if(!east)point(out,c[0]+2,c[1]+1,INK);point(out,c[0]+1,c[1]+3,SKIN[1]);}
    point(out,c[0]+4,c[1],CYAN);point(out,c[0]+4,c[1]+1,CYAN);point(out,c[0]+3,c[1]+2,CYAN);
}
function portraitHero(body,gear,fx,e){
    var t=e.frame/Math.max(1,e.count-1),p=t*Math.PI*2,state=e.state,north=e.direction==='north',east=e.direction==='east'||e.direction==='west';
    var walk=state==='walk'?Math.sin(p):0,death=state==='death'?t:0,roll=state==='dodge'?Math.sin(t*Math.PI):0;
    var lean=(state==='attack'?Math.sin(t*Math.PI)*2:0)-(state==='windup'?t:0),cx=48+lean;
    var hips=[cx,64+roll*2],chest=[cx+lean,54+roll*3+death*9],head=[chest[0]+(east?1:0),45+Math.sin(p)*.7+roll*4+death*18];
    for(var side=-1;side<=1;side+=2){
        var foot=[48+side*(east?2:4)+walk*side*3+death*side*5,72-Math.max(0,-walk*side)*2];
        var knee=[hips[0]+side*3+walk*side*2,68+roll];
        arm(body,offset(hips,side*3,0),knee,offset(foot,0,-2),3,SCARF);
        box(body,foot[0]-2,foot[1]-2,5,3,SCARF[0]);line(body,offset(foot,-1,-2),offset(foot,2,-2),METAL[2],1);
        point(body,knee[0],knee[1],COAT[3]);
    }
    var cloth=walk*.9+Math.sin(p)*.3;
    poly(body,[[chest[0]-6,chest[1]-3],[chest[0]+5,chest[1]-3],[hips[0]+7+cloth,69],[hips[0]+4,70],[hips[0]+2,67],[hips[0]-1,70],[hips[0]-3,67],[hips[0]-7+cloth,70]],COAT,true);
    poly(body,[[chest[0]-3,chest[1]-2],[chest[0]+3,chest[1]-2],[hips[0]+3,65],[hips[0]-3,65]],SCARF,false);
    line(body,offset(chest,-5,-1),offset(hips,-4,3),COAT[4],1);line(body,offset(chest,5,-1),offset(hips,4,2),COAT[1],1);
    for(var side=-1;side<=1;side+=2){line(body,[hips[0]+side*5,64],[hips[0]+side*6+cloth,68],COAT[0],1);point(body,hips[0]+side*5,65,COAT[4]);}
    line(body,offset(chest,-5,-2),offset(hips,3,1),INK,2);line(body,offset(chest,-5,-2),offset(hips,3,1),COAT[3],1);
    box(body,hips[0]-5,63,10,2,SCARF[0]);box(body,hips[0]+2,63,3,2,COAT[4]);
    if(north){plate(body,chest[0]-5,chest[1]+1,9,9,SCARF);line(body,offset(chest,-3,2),offset(chest,-3,8),COAT[4],1);point(body,chest[0]+2,chest[1]+3,CYAN);}
    else {ellipseRing(body,offset(chest,0,5),2,3,1,METAL);point(body,chest[0],chest[1]+6,WHITE);}
    var aim=east?0:(north?-Math.PI/2:Math.PI/2),swing=state==='attack'?-1.7+t*3.1:(state==='windup'?-t:0);
    var shoulder=offset(chest,5,1),elbow=offset(chest,7,5),hand=offset(chest,7,10);
    if(state==='attack'||state==='windup'){hand=polar(shoulder,9,aim+swing*.7);elbow=polar(shoulder,5,aim+swing*.5+.3);}
    if(death){hand=offset(chest,9,4);elbow=offset(chest,7,2);}
    arm(gear,shoulder,elbow,hand,3,COAT);point(gear,hand[0],hand[1],SKIN[3]);
    arm(gear,offset(chest,-5,1),offset(chest,-7,5),offset(chest,-6,10-walk),3,COAT);point(gear,chest[0]-6,chest[1]+10-walk,SKIN[3]);
    if(state==='attack'||state==='windup')blade(gear,fx,hand,aim+swing,23,1.5,CYAN,state==='attack'&&t>.1&&t<.8);
    else {line(body,offset(chest,-5,-5),offset(hips,5,3),INK,3);line(body,offset(chest,-5,-5),offset(hips,5,3),MID,1);line(body,offset(chest,-7,-6),offset(chest,-3,-8),COAT[4],2);}
    hairHead(body,head,north,east,false);
    poly(gear,[[head[0]-5,head[1]+4],[head[0],head[1]+6],[head[0]+5,head[1]+3],[head[0]+6,head[1]+6],[head[0]+2,head[1]+8],[head[0]-5,head[1]+6]],SCARF,true);
    var tail=offset(chest,-5+cloth,6);line(gear,offset(head,-4,6),tail,SCARF[1],2);point(gear,tail[0],tail[1],SCARF[3]);
    if(state==='hurt')for(var i=0;i<3;i++)point(fx,chest[0]+7+i,chest[1]-e.frame+i,GOLD);
    if(state==='exposed'){line(gear,offset(chest,-4,0),offset(chest,4,1),SCARF[0],1);}
}
function aerialHuman(body,gear,fx,e,hero){
    var t=e.frame/Math.max(1,e.count-1),p=t*Math.PI*2,state=e.state,c=hero?[48,48]:[64,64];
    var walk=state==='walk'||state==='charge'?Math.sin(p):0,death=state==='death'?t:0,prepare=state==='windup'?t:0,attack=state==='attack'?Math.sin(t*Math.PI):0;
    var k=hero?1:1.6,pal=hero?COAT:IVORY,back=hero?SCARF:BURGUNDY;
    var lean=state==='attack'?attack*3:(state==='windup'?-prepare*2:0);
    c=offset(c,0,lean);
    // Cloak trails behind the shoulders; boots are foreshortened below the hips.
    poly(body,[[c[0]-7*k,c[1]-7*k],[c[0]+7*k,c[1]-7*k],[c[0]+(10+walk)*k,c[1]-17*k],[c[0]+3*k,c[1]-15*k],[c[0],c[1]-18*k],[c[0]-4*k,c[1]-15*k],[c[0]-(9-walk)*k,c[1]-17*k]],back,true);
    for(var side=-1;side<=1;side+=2){
        var hip=offset(c,side*4*k,5*k),knee=offset(c,side*(5+walk*.7)*k,(9+walk*side*2)*k),foot=offset(c,side*5*k,(12+walk*side*3-death*3)*k);
        arm(body,hip,knee,foot,3*k,METAL);plate(body,foot[0]-2*k,foot[1]-2*k,5*k,4*k,hero?SCARF:IVORY);
    }
    dome(body,offset(c,0,2*k),8*k,11*k,pal);
    poly(body,[[c[0]-12*k,c[1]-2*k],[c[0]-8*k,c[1]-7*k],[c[0]+8*k,c[1]-7*k],[c[0]+12*k,c[1]-2*k],[c[0]+7*k,c[1]+5*k],[c[0]-7*k,c[1]+5*k]],pal,true);
    if(hero){line(body,offset(c,-7,-4),offset(c,4,9),SCARF[0],3);line(body,offset(c,-7,-4),offset(c,4,9),COAT[4],1);ellipseRing(body,offset(c,0,4),2,3,1,METAL);}
    else {for(var i=0;i<3;i++)ellipseRing(body,offset(c,0,2+i*3),8*k,4*k,1,COPPER);crest(body,c[0],c[1]+6,1,GOLD);for(var side=-1;side<=1;side+=2)gridVent(body,c[0]+side*13-4,c[1]-7,8,12,GOLD);}
    var swing=state==='attack'?-1.4+t*3.0:(state==='windup'?-prepare*1.2:.1);
    var shoulder=offset(c,10*k,0),elbow=offset(c,(15+prepare*2)*k,(6-prepare*3)*k),hand=offset(c,(13+attack*2)*k,(13-prepare*7)*k);
    if(state==='attack'||state==='windup')hand=polar(shoulder,12*k,Math.PI/2+swing*.8);
    if(death){hand=offset(c,16*k,8*k);elbow=offset(c,14*k,3*k);}
    arm(gear,shoulder,elbow,hand,4*k,pal);
    blade(gear,fx,hand,Math.PI/2+swing,hero?23:35,hero?1.5:3,hero?CYAN:RED,state==='attack'&&t>.1&&t<.8);
    var other=offset(c,-(14+prepare*2)*k,(10-prepare*4)*k);
    arm(gear,offset(c,-10*k,0),offset(c,-15*k,4*k),other,4*k,pal);
    if(!hero){
        poly(gear,[[other[0]-11,other[1]-13],[other[0]+9,other[1]-11],[other[0]+11,other[1]+10],[other[0]-1,other[1]+17],[other[0]-12,other[1]+8]],IVORY,true);
        seam(gear,offset(other,-8,-10),offset(other,-8,8),COPPER);crest(gear,other[0],other[1],1.6,COPPER[2]);
        for(var i=0;i<3;i++)rivet(gear,other[0]+7,other[1]-7+i*7);
    }
    var head=offset(c,0,-8*k+death*7+Math.sin(p)*.9);
    if(hero){hairHead(body,head,false,false,true);poly(gear,[[head[0]-6,head[1]+5],[head[0]+6,head[1]+4],[head[0]+7,head[1]+8],[head[0]-5,head[1]+9]],SCARF,true);}
    else {dome(body,head,8,10,IVORY);ellipseRing(body,head,7,9,1,COPPER);line(body,offset(head,0,-9),offset(head,0,5),GOLD,2);line(body,offset(head,-5,5),offset(head,5,5),INK,2);line(body,offset(head,-4,6),offset(head,4,6),CYAN,1);}
    if(state==='exposed'){ellipseRing(fx,offset(c,0,4),5+Math.sin(p),7,1,[INK,RUST,GOLD,GOLD,WHITE]);}
    if(state==='shoot'&&!hero){var muzzle=offset(other,0,17);bone(gear,other,muzzle,5,METAL);if(e.frame===1||e.frame===3)for(var i=-1;i<=1;i++)line(fx,muzzle,polar(muzzle,8,Math.PI/2+i*.4),GOLD,2);}
    if(state==='hurt')for(var i=0;i<5;i++)point(fx,c[0]-12+i*5,c[1]+e.frame-7+i%2,GOLD);
    if(state==='dodge'){ellipseRing(fx,c,13*k,17*k,1,[INK,STEEL,MID,HIGH,WHITE]);}
}
function legFromAbove(body,gear,c,angle,e,pal,seed){
    var t=e.frame/Math.max(1,e.count-1),walk=e.state==='walk'||e.state==='charge'?Math.sin(t*Math.PI*2+seed):0;
    var attack=e.state==='attack'?Math.sin(t*Math.PI):0,prep=e.state==='windup'?t:0,death=e.state==='death'?t:0;
    var hip=polar(c,23,angle),knee=polar(c,36+walk*3,angle+walk*.06),foot=polar(c,49+attack*5-death*8,angle+.15+walk*.07-prep*.08);
    arm(body,hip,knee,foot,7,pal);pipeJoint(gear,knee,4,METAL);plate(gear,foot[0]-4,foot[1]-3,8,7,pal);
    cable(gear,hip,polar(c,40,angle-.13),offset(knee,2,0),COPPER,1);
}
function overheadMachine(body,gear,fx,e,kind){
    var c=[64,64],t=e.frame/Math.max(1,e.count-1),p=t*Math.PI*2,state=e.state,open=state==='exposed'?1:0,windup=state==='windup'?t:0,attack=state==='attack'?Math.sin(t*Math.PI):0;
    var pal=kind==='caldera'?COPPER:METAL,accent=kind==='coro'?CYAN:GOLD;
    // Planar hardware: visible roofs, hub covers and bolted deck plates.
    if(kind==='recaudador'){
        for(var side=-1;side<=1;side+=2){
            var x=64+side*31;
            poly(body,[[x-10,31],[x+10,31],[x+12,38],[x+12,91],[x+8,99],[x-8,99],[x-12,92],[x-12,38]],METAL,true);
            for(var i=0;i<11;i++){var y=35+i*5+((state==='walk'||state==='charge')?e.frame%3:0);line(body,[x-9,y],[x+9,y],INK,2);line(body,[x-8,y-1],[x+8,y-1],HIGH,1);}
            for(var y=42;y<90;y+=14)pipeJoint(body,[x,y],5,METAL);
        }
        poly(body,[[42,29],[84,29],[92,39],[89,88],[78,99],[48,99],[36,88],[36,40]],METAL,true);
        gridVent(body,45,34,38,15,GOLD);gridVent(body,43,74,17,17,GOLD);gridVent(body,68,74,17,17,GOLD);
        dome(gear,[64,41],7,6,METAL);for(var i=0;i<7;i++)line(gear,[64,41],polar([64,41],5,p+i*Math.PI*2/7),HIGH,1);
        dome(body,c,20,22,METAL);ellipseRing(body,c,20,22,3,COPPER);
        dome(gear,c,9+open*3,11+open*2,[INK,RUST,GOLD,GOLD,WHITE]);
        for(var side=-1;side<=1;side+=2){
            var xx=64+side*(7+open*15);
            poly(gear,[[xx-7,47],[xx+6,46],[xx+9,71],[xx+4,79],[xx-7,77]],METAL,true);
            gridVent(gear,xx-4,52,8,17,GOLD);
            var shoulder=[64+side*24,76],elbow=[64+side*(41+windup*2),82-windup*13],hand=[64+side*(42+attack*8),99-windup*10+attack*3];
            arm(gear,shoulder,elbow,hand,8,METAL);pipeJoint(gear,elbow,4,COPPER);
            bone(gear,hand,offset(hand,-5-attack*3,10),4,METAL);bone(gear,hand,offset(hand,5+attack*3,10),4,METAL);
        }
        poly(gear,[[23,102+open*5],[104,102+open*5],[110,111],[100,119],[28,119],[18,111]],METAL,true);
        for(var i=0;i<10;i++)line(gear,[28+i*8,106],[24+i*8,114],i%2?GOLD:RUST,2);
    }else{
        var legs=kind==='caldera'?6:6;
        for(var i=0;i<legs;i++)legFromAbove(body,gear,c,-Math.PI+.35+i*(Math.PI*2/legs),e,pal,i*Math.PI*.8);
        dome(body,c,32,35,pal);ellipseRing(body,c,32,35,3,METAL);
        for(var i=0;i<10;i++){var at=polar(c,29,i*Math.PI/5);pipeJoint(body,at,2,COPPER);}
        if(kind==='caldera'){
            // Boiler lid, circular flues and radial pressure piping seen from above.
            dome(body,c,24,27,COPPER);ellipseRing(body,c,23,26,3,METAL);
            for(var i=0;i<3;i++){
                var at=[48+i*16,36+(i%2)*4];
                dome(gear,at,8,7,METAL);dome(gear,at,5,4,[INK,RUST,RUST,GOLD,WHITE]);ellipseRing(gear,at,8,7,2,COPPER);
                for(var r=-2;r<3;r+=2)line(gear,offset(at,r,-3),offset(at,r,3),INK,1);
            }
            gridVent(body,45,58,14,23,GOLD);gridVent(body,70,58,14,23,GOLD);
            dome(gear,c,12,14,[INK,RUST,GOLD,GOLD,WHITE]);
            for(var side=-1;side<=1;side+=2){
                var at=offset(c,side*(8+open*13),3);
                poly(gear,[[at[0]-7,at[1]-16],[at[0]+6,at[1]-16],[at[0]+9,at[1]+11],[at[0]+4,at[1]+18],[at[0]-7,at[1]+16]],COPPER,true);
                recess(gear,at[0]-3,at[1]-10,6,19,GOLD);
                cable(gear,[64+side*24,47],[64+side*38,67],[64+side*23,87],COPPER,3);
                dome(gear,[64+side*20,91],6,5,METAL);for(var i=0;i<3;i++)line(gear,[64+side*20,91],polar([64+side*20,91],4,p+i*Math.PI*2/3),HIGH,1);
            }
            dome(gear,[64,91],6,7,METAL);line(gear,[64,91],polar([64,91],4,p*.5),RED,1);
        }else{
            poly(body,[[40,41],[55,31],[77,33],[91,47],[90,81],[76,97],[50,96],[36,79]],METAL,true);
            for(var side=-1;side<=1;side+=2){gridVent(gear,64+side*23-5,48,10,30,CYAN);cable(gear,[64+side*17,88],[64+side*30,103],[64+side*33,80],COPPER,2);}
            dome(gear,c,20,23,METAL);ellipseRing(gear,c,19,22,3,COPPER);dome(gear,c,14,16,[INK,STEEL,MID,HIGH,WHITE]);
            arc(gear,c,12,p*.6,p*.6+4.6,CYAN,2);dome(gear,c,open?10:5,open?11:6,[INK,STEEL,RED,CYAN,WHITE]);
            for(var side=-1;side<=1;side+=2){var at=[64+side*29,29+Math.sin(p+side)*2];arm(body,[64+side*14,43],[64+side*24,32],at,4,METAL);dome(gear,at,9,8,COPPER);ellipseRing(gear,at,8,7,2,METAL);line(gear,at,polar(at,6,p),HIGH,1);}
            gridVent(gear,53,88,22,9,CYAN);
        }
    }
    if(state==='shoot'){
        var muzzle=[64,kind==='recaudador'?119:102];plate(gear,59,muzzle[1]-9,10,10,METAL);
        if(e.frame===1||e.frame===3)for(var i=-1;i<=1;i++)line(fx,muzzle,polar(muzzle,6,Math.PI/2+i*.4),GOLD,2);
    }
    if(state==='hurt')for(var i=0;i<6;i++)point(fx,40+i*9,57+((i+e.frame)%4)*3,GOLD);
    if(state==='death')for(var i=0;i<8;i++){var at=polar(c,20+t*20,p+i*2.4);box(fx,at[0],at[1],2,2,i%2?RUST:GOLD);}
    if(open)ellipseRing(fx,c,17+Math.sin(p),20,1,[INK,RUST,GOLD,GOLD,WHITE]);
}
function overheadMother(body,gear,fx,e){
    var c=[64,64],t=e.frame/Math.max(1,e.count-1),p=t*Math.PI*2,state=e.state,open=state==='exposed'?1:0,attack=state==='attack'||state==='shoot'?Math.sin(t*Math.PI):0;
    // Full radial crown, not a frontal arch. Segments hinge around the ground centre.
    for(var i=0;i<12;i++){
        var a=i*Math.PI/6+p*.035,at=polar(c,40+open*4+Math.sin(p+i)*.7,a);
        bone(body,polar(c,21,a),at,4,COPPER);
        var tangent=a+Math.PI/2,side=[Math.cos(tangent)*6,Math.sin(tangent)*6],along=[Math.cos(a)*9,Math.sin(a)*9];
        poly(body,[[at[0]-side[0]-along[0],at[1]-side[1]-along[1]],[at[0]+side[0]-along[0],at[1]+side[1]-along[1]],[at[0]+side[0]+along[0],at[1]+side[1]+along[1]],[at[0]-side[0]+along[0],at[1]-side[1]+along[1]]],i%3?METAL:COPPER,true);
        var inn=polar(c,37+open*4,a);point(body,inn[0],inn[1],CYAN);rivet(body,at[0],at[1]);
    }
    for(var i=0;i<6;i++){
        var a=i*Math.PI/3+.4,hip=polar(c,17,a),elbow=polar(c,31,a+.18+Math.sin(p+i)*.1),hand=polar(c,49+attack*7-open*6,a+.1);
        arm(gear,hip,elbow,hand,5,METAL);cable(gear,hip,polar(c,30,a-.2),hand,COPPER,1);bone(gear,hand,polar(hand,6,a-.5),3,IVORY);bone(gear,hand,polar(hand,6,a+.5),3,IVORY);
    }
    dome(body,c,25,29,BURGUNDY);ellipseRing(body,c,24,28,2,COPPER);
    for(var side=-1;side<=1;side+=2){gridVent(body,64+side*17-4,49,8,27,CYAN);cable(body,[64+side*9,38],[64+side*28,68],[64+side*10,89],SCARF,3);}
    dome(gear,c,16,20,METAL);ellipseRing(gear,c,15,19,2,COPPER);dome(gear,c,open?11:7,open?15:11,[INK,STEEL,CYAN,CYAN,WHITE]);
    for(var i=0;i<4;i++){var at=polar(c,18,p*.5+i*Math.PI/2);pipeJoint(gear,at,2,COPPER);}
    var head=[64,43];dome(gear,head,7,8,IVORY);poly(gear,[[56,42],[57,35],[61,38],[64,32],[67,38],[71,35],[72,42]],COPPER,true);line(gear,[60,47],[68,47],RED,1);
    for(var side=-1;side<=1;side+=2)cable(gear,[64+side*7,40],[64+side*20,50],[64+side*17,71],HAIR,3);
    if(state==='hurt')for(var i=0;i<6;i++)point(fx,43+i*8,60+(e.frame+i)%4,GOLD);
    if(state==='death')for(var i=0;i<9;i++){var at=polar(c,18+t*28,i*2.4+p*.1);box(fx,at[0],at[1],2,2,CYAN);}
}
function renderProjection(body,gear,fx,e,id){
    if(id==='portador')portraitHero(body,gear,fx,e);
    else if(id==='portador_cenital')aerialHuman(body,gear,fx,e,true);
    else if(id==='prefecto')aerialHuman(body,gear,fx,e,false);
    else if(id==='madre')overheadMother(body,gear,fx,e);
    else overheadMachine(body,gear,fx,e,id);
}
