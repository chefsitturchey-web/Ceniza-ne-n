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

// Upright 3/4 views. Each view is drawn independently, never rotated as a bitmap.
// Deliberate colour clusters: flesh hands and cloth elbows have no metal joints.
function stamp(out,rows,x,y,palette,k){
    k=k||1;
    for(var r=0;r<rows.length;r++)for(var c=0;c<rows[r].length;c++){
        var col=palette[rows[r].charAt(c)];if(!col)continue;
        for(var yy=Math.round(y+r*k);yy<Math.round(y+(r+1)*k);yy++)
            for(var xx=Math.round(x+c*k);xx<Math.round(x+(c+1)*k);xx++)point(out,xx,yy,col);
    }
}
var HUMAN_HEAD={
    south:['...hhhhhh...','..hHhhhhhh..','.hHHhhhhhhh.','.hhhhhhhhhh.','.hhsfhhsshh.','.hfffffffch.','..fefsfefc..','..ffffFff...','...ssmss....','....ss......'],
    north:['...hhhhhh...','..hHhhhhhh..','.hHHhhhhhhh.','.hHhhhhhhhh.','.hhhhhhhhhh.','.hhhhhhhhhh.','..hhhhhhhh..','..hhhhhchh..','...hsssh....','....ss......'],
    east:['....hhhh....','..hHhhhhh...','.hHHhhhhhh..','.hhhhhhhhh..','.hhhhsfffh..','.hhhsfefsf..','..hhfffffff.','...hsfffs...','....ssmm....','....ss......'],
    west:['....hhhh....','...hhhhhHh..','..hhhhhhHHh.','..hhhhhhhhh.','..hfffshhhh.','..fsfefshhh.','.ffffffchh..','...sfffsh...','....mmss....','....ss......']
};
var HELMET={
    south:['....gg......','...gGGg.....','..aAAAAa....','.aALLLLAa...','.aALLLLAa...','.aLLLLLLAa..','.aAeeeeAAa..','..aAeceAa...','..aAllAAa...','...aAAAa....'],
    north:['....gg......','...gGGg.....','..aAAAAa....','.aALLLLAa...','.aALLLLAa...','.aALLLLAa...','.aAALLAAa...','..aAALLAa...','..aAAllAa...','...aAAAa....'],
    east:['....gg......','...gGGg.....','..aAAAAa....','.aALLLLAa...','.aLLLLLLAa..','.aAeeeeAAa..','..aAllllAA..','..aAllAAa...','...aAAAa....','....aaa.....'],
    west:['......gg....','.....gGGg...','....aAAAAa..','...aALLLLAa.','..aALLLLLLAa','..aAAeeeeAa.','..AAllllAa..','...aAAllAa..','....aAAAa...','.....aaa....']
};
function clothLimb(out,a,b,c,width,pal){
    line(out,a,b,INK,width+2);line(out,b,c,INK,width+1);
    line(out,a,b,pal[2],width);line(out,b,c,pal[1],width);
    line(out,offset(a,-1,0),offset(b,-1,0),pal[3],1);
}
function person(body,gear,fx,e,id){
    var boss=id==='prefecto',hero=!boss,side=id==='portador',k=boss?1.55:1;
    var ground=boss?[64,90]:(side?[48,72]:[48,60]);
    var t=e.frame/Math.max(1,e.count-1),state=e.state,dir=e.direction;
    var north=dir==='north',profile=dir==='east'||dir==='west',sign=dir==='west'?-1:1;
    var walking=state==='walk'||state==='charge',stride=walking?[0,2,3,1,0,-2,-3,-1][e.frame%8]:0;
    var breath=[0,0,-1,-1,0,1][e.frame%6],bounce=walking?[0,1,0,-1,0,1,0,-1][e.frame%8]:breath;
    var dodge=state==='dodge'?Math.sin(t*Math.PI):0,death=state==='death'?t:0;
    var hurt=state==='hurt'?-Math.sin(t*Math.PI)*2:0;
    var cx=ground[0]+hurt,gy=ground[1],cy=gy-(24-bounce-dodge*3-death*11)*k;
    var pal=boss?IVORY:COAT,cloth=boss?BURGUNDY:SCARF;
    var aim=dir==='east'?0:(dir==='west'?Math.PI:(north?-Math.PI/2:Math.PI/2));
    // Feet and trousers remain below the head for every orientation.
    for(var s=-1;s<=1;s+=2){
        var hip=[cx+s*(profile?1:3)*k,gy-12*k];
        var knee=[cx+(profile?stride*s*.7:s*3)*k,gy-(7+Math.max(0,-stride*s)*.5)*k];
        var foot=[cx+(profile?stride*s:s*3)*k,gy-Math.max(0,stride*s)*k*.6];
        if(death)foot[0]+=s*death*6*k;
        clothLimb(body,hip,knee,offset(foot,0,-2*k),3*k,boss?IVORY:SCARF);
        box(body,foot[0]-2*k,foot[1]-3*k,4*k,4*k,boss?METAL[1]:SCARF[1]);
        line(body,offset(foot,-1,-2*k),offset(foot,1,-2*k),boss?IVORY[3]:SCARF[3],k);
    }
    if(boss){
        poly(body,[[cx-8*k,cy],[cx+8*k,cy],[cx+(11+stride*.25)*k,gy-3*k],[cx+4*k,gy-5*k],[cx,gy-2*k],[cx-4*k,gy-6*k],[cx-(10-stride*.25)*k,gy-3*k]],BURGUNDY,false);
        for(var s=-1;s<=1;s+=2)line(body,[cx+s*7*k,cy+2*k],[cx+s*8*k,gy-5*k],BURGUNDY[3],k);
    }
    var w=profile?5:7;
    poly(body,[[cx-w*k,cy],[cx+w*k,cy],[cx+(w+1)*k,cy+6*k],[cx+(w-1)*k,cy+14*k],[cx+2*k,cy+15*k],[cx,cy+12*k],[cx-2*k,cy+15*k],[cx-(w-1)*k,cy+14*k],[cx-(w+1)*k,cy+6*k]],pal,false);
    if(north){
        // Back seam and shoulder yoke, no face or chest medallion on the back.
        line(body,[cx-w*k,cy+2*k],[cx+w*k,cy+2*k],pal[4],k);
        line(body,[cx,cy+3*k],[cx,cy+12*k],pal[1],k);
        if(hero){box(body,cx-4*k,cy+5*k,8*k,6*k,COAT[1]);line(body,[cx-3*k,cy+6*k],[cx+2*k,cy+6*k],COAT[3],k);}
    }else{
        poly(body,[[cx-4*k,cy],[cx+4*k,cy],[cx+2*k,cy+10*k],[cx-2*k,cy+10*k]],cloth,false);
        line(body,[cx-4*k,cy+k],[cx-2*k,cy+9*k],pal[4],k);
        line(body,[cx+4*k,cy+k],[cx+2*k,cy+9*k],pal[1],k);
        line(body,[cx-4*k,cy+2*k],[cx+3*k,cy+10*k],pal[0],2*k);
        line(body,[cx-4*k,cy+2*k],[cx+3*k,cy+10*k],pal[3],k);
        box(body,cx-5*k,cy+10*k,10*k,2*k,cloth[0]);box(body,cx+k,cy+10*k,2*k,2*k,COPPER[3]);
        if(!profile){ellipseRing(body,[cx,cy+6*k],k,2*k,1,METAL);point(body,cx,cy+6*k,WHITE);}
    }
    // Arm swing opposes the stride. Sleeves, flesh hands, and discrete shoulders.
    var prep=state==='windup'?t:0,attacking=state==='attack'||state==='windup';
    var hand=[cx+(profile?sign*5:8)*k,cy+(11+(walking?-stride*.6:breath*.3))*k];
    var shoulder=[cx+(profile?sign*3:6)*k,cy+2*k],elbow=[cx+(profile?sign*5:8)*k,cy+7*k];
    var swing=state==='attack'?-1.3+t*2.6:-prep*1.1;
    if(attacking){hand=polar(shoulder,10*k,aim+swing*.6);elbow=polar(shoulder,5*k,aim+swing*.4+.35);}
    if(death){hand=offset(shoulder,10*k,7*k);elbow=offset(shoulder,6*k,5*k);}
    var farShoulder=[cx-(profile?sign*3:6)*k,cy+2*k],farElbow=[cx-(profile?sign*4:8)*k,cy+7*k],farHand=[cx-(profile?sign*4:8)*k,cy+(11+(walking?stride*.6:0))*k];
    clothLimb(gear,farShoulder,farElbow,farHand,3*k,pal);
    box(gear,farHand[0]-k,farHand[1],2*k,2*k,boss?IVORY[2]:SKIN[3]);
    clothLimb(gear,shoulder,elbow,hand,3*k,pal);
    box(gear,hand[0]-k,hand[1],2*k,2*k,boss?IVORY[2]:SKIN[3]);
    if(boss){
        for(var s=-1;s<=1;s+=2){dome(gear,[cx+s*7*k,cy+2*k],4*k,3*k,IVORY);line(gear,[cx+s*7*k-3*k,cy+2*k],[cx+s*7*k+3*k,cy+2*k],COPPER[3],k);}
        var sh=farHand;
        poly(gear,[[sh[0]-7*k,sh[1]-7*k],[sh[0]+6*k,sh[1]-7*k],[sh[0]+6*k,sh[1]+5*k],[sh[0],sh[1]+11*k],[sh[0]-7*k,sh[1]+5*k]],north?METAL:IVORY,false);
        if(!north){seam(gear,offset(sh,-5*k,-5*k),offset(sh,-5*k,4*k),COPPER);crest(gear,sh[0],sh[1],k,COPPER[3]);}
    }
    if(attacking||boss||!side){
        var angle=attacking?aim+swing:(profile?Math.PI/2+sign*.15:Math.PI/2+.2);
        blade(gear,fx,hand,angle,boss?30:21,boss?2:1,CYAN,state==='attack'&&t>.1&&t<.8);
    }else{line(body,[cx-5,cy-1],[cx+4,cy+12],SCARF[0],3);line(body,[cx-6,cy-2],[cx-3,cy-4],COPPER[3],2);}
    var hx=cx-6*k,hy=cy-10*k;
    stamp(body,(boss?HELMET:HUMAN_HEAD)[dir],hx,hy,boss?{a:IVORY[0],A:IVORY[2],L:IVORY[3],l:IVORY[1],g:COPPER[1],G:GOLD,e:INK,c:CYAN}:{h:HAIR[1],H:HAIR[2],s:SKIN[1],f:SKIN[2],F:SKIN[3],e:HAIR[0],m:SKIN[0],c:CYAN},k);
    if(hero){
        poly(gear,[[cx-5*k,cy-1*k],[cx-2*k,cy+1*k],[cx+5*k,cy-1*k],[cx+5*k,cy+2*k],[cx,cy+4*k],[cx-5*k,cy+2*k]],SCARF,false);
        line(gear,[cx-4*k,cy+2*k],[cx-(5+stride*.3)*k,cy+8*k],SCARF[2],2*k);
    }
    if(state==='hurt')for(var i=0;i<4;i++)point(fx,cx+10+i,cy+e.frame-i,GOLD);
    if(state==='exposed'){point(gear,cx-5*k,cy+2*k+breath,CYAN);}
    if(state==='shoot')point(fx,hand[0]+e.frame,hand[1]-2,GOLD);
    LAST_HEAD=[cx+ORIGIN,hy+4*k+ORIGIN];LAST_FEET=[ground[0]+ORIGIN,gy+ORIGIN];
}

// Ground-plane orientation, followed by a fixed 3/4 camera projection.
// Positive depth is forward; height always projects UP the screen.
var VIEW={cx:64,cy:84,dx:0,dy:1};
function world(x,depth,height){return [VIEW.cx+x*VIEW.dy+depth*VIEW.dx,VIEW.cy+(depth*VIEW.dy-x*VIEW.dx)*.55-height];}
function setView(e){VIEW.dx=e.direction==='east'?1:(e.direction==='west'?-1:0);VIEW.dy=e.direction==='south'?1:(e.direction==='north'?-1:0);}
function block3(out,x,y,z,w,d,h,pal){
    var corners=[[x-w/2,y-d/2],[x+w/2,y-d/2],[x+w/2,y+d/2],[x-w/2,y+d/2]],faces=[];
    for(var i=0;i<4;i++){var j=(i+1)%4,a=corners[i],b=corners[j];faces.push({at:(world(a[0],a[1],0)[1]+world(b[0],b[1],0)[1])/2,a:a,b:b});}
    faces.sort(function(a,b){return a.at-b.at;});
    for(var i=0;i<faces.length;i++){var f=faces[i];poly(out,[world(f.a[0],f.a[1],z),world(f.b[0],f.b[1],z),world(f.b[0],f.b[1],z+h),world(f.a[0],f.a[1],z+h)],pal,false);}
    var roof=[];for(var i=0;i<4;i++)roof.push(world(corners[i][0],corners[i][1],z+h));poly(out,roof,pal,false);
    for(var i=0;i<4;i++){var p=roof[i];point(out,p[0]+1,p[1]+1,pal[4]);}
}
function vent3(out,x,y,z,w,d,accent){
    block3(out,x,y,z,w,d,2,METAL);
    for(var v=-d/2+3;v<d/2-1;v+=3){line(out,world(x-w/2+2,y+v,z+3),world(x+w/2-2,y+v,z+3),INK,2);point(out,world(x-w/2+3,y+v,z+3)[0],world(x-w/2+3,y+v,z+3)[1],accent);}
}
function hullPanel(out,side,back,z,accent){
    // Service panels on the face that is actually visible to the fixed camera.
    function at(a,h){return side?world(side*22,a,h):world(a,back,z+h);}
    var lo=side?z:0,hi=side?z+15:15;
    poly(out,[at(-15,lo),at(15,lo),at(15,hi),at(-15,hi)],METAL,false);
    poly(out,[at(-12,lo+3),at(12,lo+3),at(12,hi-3),at(-12,hi-3)],[INK,DEEP,STEEL,MID,HIGH],false);
    for(var a=-10;a<12;a+=4){line(out,at(a,lo+4),at(a,hi-4),MID,2);var p=at(a,hi-3);point(out,p[0],p[1],accent);}
    for(var a=-13;a<15;a+=26){var p=at(a,hi-1);rivet(out,p[0],p[1]);}
}
function cylinder(out,x,y,z,r,h,pal){
    var c=world(x,y,z),top=world(x,y,z+h);
    poly(out,[[c[0]-r,c[1]],[c[0]-r,top[1]],[c[0]+r,top[1]],[c[0]+r,c[1]]],pal,false);
    dome(out,c,r,r*.5,pal);box(out,c[0]-r,top[1],r*2,h,pal[1]);
    for(var i=-r+3;i<r-2;i+=5)line(out,[c[0]+i,top[1]+2],[c[0]+i,c[1]],i<0?pal[3]:pal[0],1);
    dome(out,top,r,r*.5,pal);ellipseRing(out,top,r,r*.5,1,METAL);
}
function machineLeg(body,gear,e,a,index,front){
    var t=e.frame/Math.max(1,e.count-1),step=(e.state==='walk'||e.state==='charge')?Math.sin(t*Math.PI*2+index*Math.PI):0;
    var death=e.state==='death'?t:0;
    var hip=[Math.cos(a)*20,Math.sin(a)*19,18],knee=[Math.cos(a)*34,Math.sin(a)*31+step*4,12+Math.max(0,step)*3];
    var foot=[Math.cos(a)*(43-death*8),Math.sin(a)*42+step*5,1+Math.max(0,-step)*5];
    var fp=world(foot[0],foot[1],0),isFront=fp[1]>=VIEW.cy;if(isFront!==front)return;
    var p=world(hip[0],hip[1],hip[2]),q=world(knee[0],knee[1],knee[2]),r=world(foot[0],foot[1],foot[2]);
    arm(body,p,q,r,6,METAL);pipeJoint(gear,q,3,COPPER);block3(gear,foot[0],foot[1],foot[2],9,10,3,METAL);
}
function machinery(body,gear,fx,e,id){
    setView(e);var t=e.frame/Math.max(1,e.count-1),p=t*Math.PI*2,s=e.state,death=s==='death'?t:0,open=s==='exposed'?1:0;
    var attacking=s==='attack'?Math.sin(t*Math.PI):0,prep=s==='windup'?t:0;
    VIEW.cy=84;var i,at;
    if(id==='recaudador'){
        for(var side=-1;side<=1;side+=2){
            block3(body,side*29,0,1,15,54,10,METAL);
            for(i=-23;i<26;i+=5){var advance=(s==='walk'||s==='charge')?e.frame%3:0;line(body,world(side*29-6,i+advance,12),world(side*29+6,i+advance,12),INK,2);line(body,world(side*29-6,i+advance-1,13),world(side*29+6,i+advance-1,13),HIGH,1);}
        }
        block3(body,0,0,8,43,43,22-death*6,METAL);
        vent3(body,-10,-7,31-death*6,13,24,GOLD);vent3(body,11,-7,31-death*6,13,24,GOLD);
        if(VIEW.dy)hullPanel(gear,0,VIEW.dy>0?22:-22,11-death*6,VIEW.dy>0?GOLD:CYAN);
        else hullPanel(gear,VIEW.dx>0?-1:1,0,11-death*6,CYAN);
        // Lifting eyes, a service hatch and separately routed power conduits.
        for(var side=-1;side<=1;side+=2){
            var p0=world(side*16,-15,34-death*6),p1=world(side*18,4,33-death*6),p2=world(side*14,19,30-death*6);
            cable(gear,p0,p1,p2,COPPER,1);dome(gear,p0,3,2,METAL);point(gear,p0[0],p0[1]-1,CYAN);
        }
        at=world(0,12,33-death*6);dome(gear,at,12,7,COPPER);dome(gear,at,7+open*3,4+open*2,[INK,RUST,GOLD,GOLD,WHITE]);
        for(var side=-1;side<=1;side+=2){
            block3(gear,side*(5+open*11),12,34-death*6,8,17,3,METAL);
            var a=world(side*20,8,21),b=world(side*(32+prep*3),18-prep*10,15),c=world(side*(32+attacking*5),34+attacking*14-prep*8,12);
            arm(gear,a,b,c,7,METAL);pipeJoint(gear,b,4,COPPER);
            bone(gear,c,world(side*(27+attacking*4),44+attacking*13-prep*8,10),4,METAL);
            bone(gear,c,world(side*(37+attacking*5),44+attacking*13-prep*8,10),4,METAL);
        }
        block3(gear,0,26,3,48,8,9,METAL);
        for(i=-20;i<23;i+=8)line(gear,world(i,30,5),world(i+3,30,10),GOLD,2);
        at=world(0,-13,35-death*6);dome(gear,at,5,3,METAL);for(i=0;i<7;i++)line(gear,at,offset(at,Math.cos(p+i*Math.PI*2/7)*4,Math.sin(p+i*Math.PI*2/7)*2),HIGH,1);
    }else{
        var count=id==='caldera'?6:4;
        for(i=0;i<count;i++)machineLeg(body,gear,e,i*Math.PI*2/count+.35,i,false);
        if(id==='caldera'){
            cylinder(body,0,0,8,25,28-death*8,COPPER);
            for(i=-16;i<20;i+=8){var q=world(i,23,13),r=world(i,23,31-death*8);line(gear,q,r,COPPER[0],3);line(gear,offset(q,-1,0),offset(r,-1,0),COPPER[3],1);}
            if(VIEW.dy>0){var gauge=world(0,23,24-death*8);dome(gear,gauge,5,6,METAL);dome(gear,gauge,3,4,[INK,DEEP,WHITE,WHITE,WHITE]);line(gear,gauge,offset(gauge,Math.cos(p*.3)*3,-2),RED,1);}
            for(i=-1;i<=1;i++){
                cylinder(gear,i*14,-11,34-death*8,5,12+(i===0?3:0),METAL);
                at=world(i*14,-11,46+(i===0?3:0)-death*8);dome(gear,at,4,2,[INK,RUST,RUST,GOLD,WHITE]);
                if(s==='windup'||open)for(var j=0;j<3;j++){var age=(e.frame*2+j*5)%14;dome(fx,offset(at,Math.sin(age*.5)*2,-4-age),2+age*.13,2,[rgba('536d7d',60),rgba('8299a8',100),rgba('8299a8',140),rgba('c4d2ce',90),rgba('c4d2ce',90)]);}
            }
            at=world(0,10,37-death*8);dome(gear,at,11,6,[INK,RUST,GOLD,GOLD,WHITE]);
            for(var side=-1;side<=1;side+=2){block3(gear,side*(6+open*12),10,37-death*8,9,19,3,COPPER);var valve=world(side*22,9,29-death*8);dome(gear,valve,5,4,METAL);for(i=0;i<3;i++)line(gear,valve,offset(valve,Math.cos(p+i*2.09)*4,Math.sin(p+i*2.09)*3),COPPER[3],1);}
        }else{
            block3(body,0,0,9,38,39,15-death*5,METAL);
            if(VIEW.dy>0){var panel=world(0,20,17-death*5);gridVent(gear,panel[0]-9,panel[1]-4,18,8,CYAN);}
            vent3(body,-12,2,25-death*5,10,27,CYAN);vent3(body,12,2,25-death*5,10,27,CYAN);
            at=world(0,0,34-death*7);dome(gear,at,20,12,METAL);ellipseRing(gear,at,19,11,2,COPPER);dome(gear,at,14,8,[INK,STEEL,MID,HIGH,WHITE]);
            var sweep=world(Math.cos(p)*12,Math.sin(p)*12,35-death*7);line(gear,at,sweep,CYAN,2);dome(gear,at,open?9:4,open?5:3,[INK,STEEL,CYAN,CYAN,WHITE]);
            for(var side=-1;side<=1;side+=2){var base=world(side*21,-13,15),joint=world(side*25,-18,35),dish=world(side*27,-18,46+Math.sin(p+side));arm(gear,base,joint,dish,4,METAL);dome(gear,dish,8,5,COPPER);ellipseRing(gear,dish,7,4,1,METAL);line(gear,dish,offset(dish,Math.cos(p)*5,Math.sin(p)*3),HIGH,1);}
        }
        for(i=0;i<count;i++)machineLeg(body,gear,e,i*Math.PI*2/count+.35,i,true);
    }
    // Direction is communicated by the real front attachment, not rotating the chassis image.
    var muzzle=world(0,id==='recaudador'?29:24,id==='recaudador'?17:23);
    var tip=world(0,id==='recaudador'?40:35,id==='recaudador'?17:23);
    bone(gear,muzzle,tip,5,METAL);point(gear,tip[0],tip[1],CYAN);
    if(s==='shoot'&&(e.frame===1||e.frame===3))for(i=-1;i<=1;i++)line(fx,tip,offset(tip,VIEW.dx*8+i*2,VIEW.dy*5+i*2),GOLD,2);
    if(s==='hurt')for(i=0;i<5;i++)point(fx,45+i*8,45+(e.frame+i)%4,GOLD);
    if(death)for(i=0;i<7;i++){at=offset([64,64],Math.cos(i*2.4+p)*t*30,Math.sin(i*2.4+p)*t*17);box(fx,at[0],at[1],2,2,GOLD);}
    LAST_HEAD=[64,35];LAST_FEET=[64,84];LAST_FRONT=tip;
}
function matriarch(body,gear,fx,e){
    setView(e);VIEW.cy=87;
    var t=e.frame/Math.max(1,e.count-1),p=t*Math.PI*2,s=e.state,death=s==='death'?t:0;
    var breath=Math.sin(p),open=s==='exposed'?1:0,attack=s==='attack'||s==='shoot'?Math.sin(t*Math.PI):0;
    var profile=e.direction==='east'||e.direction==='west',wide=profile?.65:1;
    // A standing, robed android. The halo stays upright, with its own hinged segments.
    var head=[64,40+breath+death*16],hips=[64,73+death*5];
    for(var i=0;i<10;i++){
        var a=i*Math.PI/5,at=[64+Math.cos(a)*(31+open*3)*wide,43+Math.sin(a)*24+breath];
        bone(body,[64+Math.cos(a)*20*wide,43+Math.sin(a)*16],at,3,COPPER);
        var dx=Math.cos(a)*5,dy=Math.sin(a)*5;
        poly(body,[[at[0]-dx-3,at[1]-dy-3],[at[0]+dx-3,at[1]+dy-3],[at[0]+dx+3,at[1]+dy+3],[at[0]-dx+3,at[1]-dy+3]],i%3?METAL:COPPER,false);point(body,at[0],at[1],CYAN);
    }
    for(var side=-1;side<=1;side+=2)for(var row=0;row<3;row++){
        var a=world(side*9,0,33-row*5),b=world(side*(24+Math.sin(p+row)*2),row*8-9,36-row*8),c=world(side*(38+attack*4),row*12-12+attack*14,32-row*6+Math.sin(p+row)*2);
        arm(gear,a,b,c,4,METAL);cable(gear,a,offset(b,0,-3),c,COPPER,1);bone(gear,c,offset(c,side*5,4),2,IVORY);
    }
    poly(body,[[53,50],[75,50],[77,72],[88,94],[78,97],[69,94],[64,99],[58,94],[49,97],[40,94],[51,72]],BURGUNDY,false);
    for(var side=-1;side<=1;side+=2){line(body,[64+side*7,67],[64+side*16,93],BURGUNDY[3],2);line(body,[64+side*8,72],[64+side*10,92],BURGUNDY[0],2);}
    poly(body,[[55,49],[73,49],[76,60],[70,76],[58,76],[52,60]],IVORY,false);
    for(var row=0;row<3;row++){line(body,[55,55+row*6],[63,59+row*6],COPPER[3],2);line(body,[73,55+row*6],[65,59+row*6],COPPER[1],2);}
    var north=e.direction==='north',sign=e.direction==='west'?-1:1;
    dome(body,head,profile?6:8,10,IVORY);line(body,offset(head,0,-9),offset(head,0,-4),COPPER[3],2);
    if(!north){line(body,offset(head,profile?sign*2:-4,0),offset(head,profile?sign*6:4,0),INK,2);line(body,offset(head,profile?sign*3:-3,0),offset(head,profile?sign*5:3,0),RED,1);if(profile)point(body,head[0]+sign*8,head[1]+3,IVORY[3]);else line(body,offset(head,-2,6),offset(head,2,6),IVORY[0],1);}
    else {for(var i=-1;i<=1;i++)line(body,offset(head,i*3,-5),offset(head,i*3,7),COPPER[1],1);point(body,head[0]+4,head[1]+5,CYAN);}
    poly(gear,[[55,head[1]-7],[54,head[1]-15],[60,head[1]-10],[64,head[1]-18],[68,head[1]-10],[74,head[1]-15],[73,head[1]-7]],COPPER,false);
    dome(gear,[64,67],open?8:4,open?10:7,[INK,STEEL,CYAN,CYAN,WHITE]);
    if(s==='hurt')for(var i=0;i<5;i++)point(fx,46+i*9,54+(e.frame+i)%4,GOLD);
    if(death)for(var i=0;i<9;i++)point(fx,64+Math.cos(i*2.4)*t*31,60+Math.sin(i*2.4)*t*21,CYAN);
    LAST_HEAD=head;LAST_FEET=[64,99];
}
var LAST_HEAD,LAST_FEET,LAST_FRONT;
function renderProjection(body,gear,fx,e,id){
    LAST_HEAD=null;LAST_FEET=null;LAST_FRONT=null;
    if(id.indexOf('portador')===0||id==='prefecto')person(body,gear,fx,e,id);
    else if(id==='madre')matriarch(body,gear,fx,e);
    else machinery(body,gear,fx,e,id);
}
