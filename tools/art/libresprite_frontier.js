// Native LibreSprite RGBA pixel drawing. All artwork and animation are original.
var INK=[11,19,30,255], DARK=[38,49,61,255], STEEL=[87,109,120,255], LIGHT=[166,187,190,255];
var CYAN=[71,218,203,255], COPPER=[151,95,63,255], RUST=[88,61,54,255], GOLD=[224,166,89,255];
var W,H,out;
function pixel(x,y,c){x=Math.round(x);y=Math.round(y);if(x<0||x>=W||y<0||y>=H)return;var p=(y*W+x)*4;for(var k=0;k<4;k++)out[p+k]=c[k];}
function rect(x,y,w,h,c){for(var j=0;j<h;j++)for(var i=0;i<w;i++)pixel(x+i,y+j,c);}
function line(x,y,a,b,c){var n=Math.max(Math.abs(a-x),Math.abs(b-y),1);for(var k=0;k<=n;k++)pixel(x+(a-x)*k/n,y+(b-y)*k/n,c);}
function ellipse(x,y,rx,ry,c){for(var j=-ry;j<=ry;j++)for(var i=-rx;i<=rx;i++)if(i*i/(rx*rx)+j*j/(ry*ry)<=1.05)pixel(x+i,y+j,c);}
function panel(x,y,w,h,c){rect(x,y,w,h,INK);rect(x+1,y+1,w-2,h-2,c);line(x+2,y+1,x+w-3,y+1,LIGHT);}
function rat(frame){
 var phase=frame*Math.PI/4,bob=frame===2||frame===6?-1:0;
 // Segmented, counter-swinging tail, separate rear/front leg contacts.
 var tip=16+Math.round(Math.sin(phase)*2);
 line(1,tip,5,16,RUST);line(5,16,9,14+bob,COPPER);pixel(2,tip-1,GOLD);
 for(var i=0;i<4;i++){
  var root=i<2?13:22, swing=Math.round(Math.sin(phase+(i%2)*Math.PI+(i<2?0:Math.PI))*2);
  line(root,15+bob,root+swing,18,INK);line(root+swing,18,root+swing+2,18,COPPER);
 }
 ellipse(17,12+bob,8,5,INK);ellipse(17,12+bob,7,4,RUST);ellipse(16,10+bob,5,2,COPPER);
 line(12,9+bob,18,8+bob,STEEL);line(12,11+bob,20,10+bob,[126,96,78,255]);
 ellipse(24,12+bob,4,3,INK);ellipse(24,11+bob,3,2,COPPER);
 ellipse(22,8+bob,2,3,INK);ellipse(22,8+bob,1,2,[178,114,107,255]);
 pixel(26,11+bob,frame===7?RUST:GOLD);pixel(28,13+bob,[191,117,111,255]);
 line(26,14+bob,30,15+bob,STEEL);line(26,13+bob,30,12+bob,STEEL);
 // Small corroded implant, not a glowing blob in place of anatomy.
 panel(15,10+bob,4,3,DARK);pixel(16,11+bob,CYAN);
 for(var k=0;k<5;k++)pixel(11+k*2,12+bob+(k%2),[107,82,68,255]);
}
function trap(frame){
 panel(3,15,26,6,DARK);panel(6,16,20,3,STEEL);
 for(var k=0;k<5;k++)line(8+k*4,17,8+k*4,18,INK);
 panel(19,10,8,5,RUST);pixel(24,12,frame===0?CYAN:GOLD);panel(9,11,8,5,STEEL);
 for(var side=0;side<2;side++){
  var x=side===0?5:25;
  line(x,16,side===0?10:21,frame===0?7:13,LIGHT);
  line(x+1,16,side===0?11:22,frame===0?7:13,STEEL);
  for(var t=0;t<4;t++)line(x+(side===0?t:-t),15-t,x+(side===0?t+2:-t-2),14-t,LIGHT);
 }
 for(var k=0;k<3;k++)panel(2+k*3,12,3,4,STEEL);
 if(frame===2){line(8,11,12,6,GOLD);line(22,10,26,6,CYAN);}
}
function battery(){
 panel(5,8,22,21,DARK);panel(7,10,18,16,STEEL);
 panel(8,5,5,5,COPPER);panel(19,5,5,5,COPPER);
 line(10,5,9,2,INK);line(21,5,25,2,COPPER);
 for(var k=0;k<3;k++){panel(9+k*5,13,4,10,DARK);rect(10+k*5,15,2,6,k===2?GOLD:CYAN);}
 panel(11,25,10,3,RUST);line(6,28,3,30,INK);line(25,26,29,30,COPPER);
 pixel(7,9,LIGHT);pixel(24,25,LIGHT);rect(8,11,2,1,GOLD);
}
function antenna(){
 panel(4,36,24,9,DARK);panel(8,31,17,8,STEEL);
 panel(14,6,4,29,DARK);line(15,8,15,32,LIGHT);
 line(6,12,25,12,STEEL);line(8,17,23,17,STEEL);line(10,22,21,22,STEEL);
 for(var x=6;x<=25;x+=19){line(x,8,x,15,LIGHT);pixel(x,7,COPPER);}
 line(15,7,23,2,STEEL);pixel(24,2,CYAN);line(16,25,6,39,COPPER);line(17,26,26,42,INK);
 panel(10,34,11,5,DARK);rect(12,35,3,2,CYAN);pixel(18,36,GOLD);
 for(var i=0;i<4;i++)rect(8+i*5,41,3,2,RUST);
}
function bag(){
 panel(4,2,8,4,RUST);panel(2,5,12,10,COPPER);panel(4,8,8,6,RUST);
 line(4,5,11,5,GOLD);panel(6,6,4,3,STEEL);pixel(7,7,CYAN);
 line(2,6,2,12,LIGHT);line(13,8,13,13,INK);line(5,11,10,11,COPPER);
}
function parts(){
 panel(1,7,8,7,STEEL);panel(3,8,4,4,DARK);pixel(4,9,CYAN);
 for(var i=0;i<3;i++){line(10,4+i*2,14,5+i*2,COPPER);pixel(9,5+i*2,GOLD);}
 ellipse(11,11,4,3,INK);ellipse(11,11,3,2,LIGHT);rect(10,10,3,3,DARK);pixel(14,11,STEEL);
 line(1,13,5,14,RUST);pixel(2,7,LIGHT);
}
function onEvent(event){if(event!=='init')return;
 for(var e=0;e<ENTRIES.length;e++){
  var entry=ENTRIES[e],doc=app.open(entry.template);W=entry.width;H=entry.height;
  for(var frame=0;frame<entry.count;frame++){
   out=new Uint8Array(W*H*4);
   if(entry.name==='rat')rat(frame);else if(entry.name==='trap')trap(frame);else if(entry.name==='battery')battery();else if(entry.name==='antenna')antenna();else if(entry.name==='parts')parts();else bag();
   doc.sprite.layer(0).cel(frame).image.putImageData(out);
  }
  doc.sprite.saveAs(entry.ase);
 }
 console.log('FRONTIER_ART_COMPLETE');
}
