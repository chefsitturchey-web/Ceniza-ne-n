// Uses approved industrial pixels; masks, texture sampling, damage and new pixels run in LibreSprite.
var raw,SW,SH;
function sample(region,x,y,w,h,tint){
 for(var j=0;j<h;j++)for(var i=0;i<w;i++){
  var sx=Math.floor(region[0]+(i+.5)*region[2]/w),sy=Math.floor(region[1]+(j+.5)*region[3]/h),p=(sy*SW+sx)*4;
  if(raw[p+3]<100)continue;
  pixel(x+i,y+j,[Math.round(raw[p]*tint[0]),Math.round(raw[p+1]*tint[1]),Math.round(raw[p+2]*tint[2]),raw[p+3]]);
 }
}
function ruin(frame){
 var zone=Math.floor(frame/2),variation=frame%2,region=BUILD.regions[(zone+variation)%4];
 var tint=[[.78,.80,.82],[.90,.72,.62],[.65,.83,.79],[.85,.82,.73],[.65,.77,.82]][zone];
 var front=BUILD.regions[variation===0?0:1],wall=[front[0]+front[2]*.15,front[1]+front[3]*.48,front[2]*.68,front[3]*.4];
 for(var floor=0;floor<3;floor++)sample(wall,19,28+floor*29,92,31,tint);
 sample(region,4,68,120,73,tint);
 // Broken parapet with exposed rebar, inset windows and weathered joints.
 for(var x=17;x<113;x++){
  var roof=23+((x*13+frame*11)%17<6?7:0);
  line(x,roof,x,29,INK);pixel(x,roof,[86,98,104,255]);
 }
 for(var floor=0;floor<2;floor++)for(var window=0;window<4;window++){
  var x=26+window*21,y=36+floor*29;
  panel(x,y,12,17,[25,35,43,255]);
  rect(x+2,y+2,8,12,(window+floor+frame)%3===0?[91,95,83,255]:[13,24,32,255]);
  line(x+5,y+2,x+5,y+13,STEEL);line(x+2,y+8,x+9,y+8,DARK);
  if((window+frame)%2===0){line(x+2,y+3,x+8,y+11,INK);pixel(x+3,y+4,LIGHT);}
 }
 for(var y=29;y<87;y+=6){line(19,y,23,y,DARK);line(107,y,112,y,STEEL);}
 // A shell opening varies by facade; no straight crop or uniformly broken roof.
 for(var y=0;y<64;y++)for(var x=0;x<W;x++){
  var edge=variation===0?102-Math.floor(y*.22):12+Math.floor(y*.18);
  if((variation===0?x>edge:x<edge)&&y<39+((x*7)%13))pixel(x,y,[0,0,0,0]);
 }
 for(var i=0;i<5;i++)line(22+i*5,24,21+i*5,12+(i%3)*4,RUST);
 line(94,27,99,52,INK);line(99,52,90,80,INK);line(91,80,96,105,INK);
 panel(36,92,47,10,DARK);line(39,94,76,94,COPPER);
 for(var i=0;i<6;i++)rect(40+i*6,96,3,2,STEEL);
 for(var i=0;i<17;i++){var x=6+(i*19)%116,y=135+(i%3);rect(x,y,5+(i%5),3,[50+i%3*9,57,62,255]);pixel(x,y,LIGHT);}
 if(zone===2){for(var i=0;i<22;i++)pixel(18+i*4,129-i%3,[55,91,76,255]);}
 if(zone===4){line(9,140,35,111,CYAN);line(35,111,42,80,STEEL);line(104,140,97,107,STEEL);}
}
function support(frame){
 var kind=Math.floor(frame/2),level=frame%2,region=BUILD.regions[[3,0,1][kind]];
 sample(region,2,25,92,66,[1,1,1]);
 var accent=[GOLD,[202,120,81,255],CYAN][kind];
 panel(8,46,14,22,DARK);rect(10,48,10,4,accent);
 for(var i=0;i<3;i++)rect(11,56+i*3,7,1,STEEL);
 line(83,44,83,16-level*8,STEEL);line(84,44,84,16-level*8,INK);
 panel(66,16-level*8,18,10,DARK);rect(69,19-level*8,12,4,accent);
 if(kind===0){panel(40,61,21,10,DARK);line(43,65,57,65,GOLD);}
 if(kind===1){for(var i=0;i<3;i++){line(35+i*9,50,38+i*9,65,STEEL);rect(33+i*9,48,5,3,RUST);}}
 if(kind===2){panel(35,59,15,19,DARK);rect(41,62,3,13,CYAN);rect(37,67,11,3,CYAN);}
 if(level){line(9,89,87,89,STEEL);panel(5,72,16,13,DARK);rect(8,75,10,6,accent);for(var i=0;i<3;i++)line(12+i*3,33,10+i*3,45,COPPER);}
}
function component(frame){
 if(frame===0){panel(4,7,16,11,STEEL);panel(7,9,10,7,DARK);ellipse(12,12,3,3,COPPER);pixel(12,12,CYAN);for(var i=0;i<4;i++)rect(5+i*4,5,2,3,LIGHT);line(17,16,21,21,COPPER);}
 if(frame===1){panel(6,3,12,19,DARK);for(var i=0;i<6;i++){line(4,6+i*2,19,7+i*2,COPPER);pixel(4,6+i*2,GOLD);}rect(10,4,4,16,[51,96,113,255]);pixel(11,5,CYAN);}
 if(frame===2){panel(4,3,16,19,STEEL);panel(6,5,12,14,DARK);for(var y=6;y<18;y+=3)for(var x=7;x<17;x+=3)pixel(x,y,CYAN);line(4,20,19,20,COPPER);rect(9,2,6,2,GOLD);}
}
function onEvent(event){if(event!=='init')return;
 var reference=app.open(BUILD.source);var input=reference.sprite.layer(0).cel(0).image;
 raw=input.getImageData();SW=input.width;SH=input.height;
 for(var e=0;e<BUILD.entries.length;e++){
  var entry=BUILD.entries[e],doc=app.open(entry.template);W=entry.width;H=entry.height;
  for(var f=0;f<entry.count;f++){out=new Uint8Array(W*H*4);if(entry.name==='ruins')ruin(f);else if(entry.name==='supports')support(f);else component(f);doc.sprite.layer(0).cel(f).image.putImageData(out);}
  doc.sprite.saveAs(entry.ase);
 }
 console.log('SETTLEMENT_ART_COMPLETE');
}
