function setNewVolume(newV, mute)
{
   var _loc3_ = mute;
   mainMute = _loc3_;
   if(!_loc3_)
   {
      currentV = newV;
   }
   sVol.setVolume(!_loc3_ ? newV : 0);
   applyMixVolumes();
}
function applyMixVolumes()
{
   var _loc1_ = !mainMute ? currentV : 0;
   if(musicSound != undefined)
   {
      musicSound.setVolume(Math.round(_loc1_ * musicMix / 100));
   }
   if(effectSound != undefined)
   {
      effectSound.setVolume(Math.round(_loc1_ * effectMix / 100));
   }
}
function clampMix(v, dflt)
{
   if(v == undefined || v == "" || isNaN(Number(v)))
   {
      return dflt;
   }
   return Math.max(0,Math.min(100,Math.round(Number(v))));
}
function setMixLevels(newMusic, newEffect)
{
   musicMix = clampMix(newMusic,musicMix);
   effectMix = clampMix(newEffect,effectMix);
   applyMixVolumes();
   return musicMix + "," + effectMix;
}
function playSfx(lbl)
{
   var _loc2_ = lbl;
   if(!musicLabels[_loc2_] && sfxFx != undefined)
   {
      MovieClip.prototype.gotoAndPlay.call(sfxFx,_loc2_);
   }
   else
   {
      MovieClip.prototype.gotoAndPlay.call(sfx,_loc2_);
   }
}
function initSoundMix()
{
   if(sfx == undefined)
   {
      return undefined;
   }
   if(sfxFx == undefined)
   {
      attachMovie("sfxClip","sfxFx",60000);
      if(sfxFx == undefined)
      {
         return undefined;
      }
      MovieClip.prototype.gotoAndStop.call(sfxFx,1);
   }
   musicSound = new Sound(sfx);
   effectSound = new Sound(sfxFx);
   sfx.gotoAndPlay = function(lbl)
   {
      root.playSfx(lbl);
   };
   applyMixVolumes();
}
_global.root = this;
_focusrect = false;
so = null;
so = SharedObject.getLocal("spiderSo");
Stage.align = "TL";
Stage.showMenu = false;
_quality = "MEDIUM";
root.storesOpen = true;
var i = 1;
while(i <= 15)
{
   if(eval("ep" + i + "version") == undefined)
   {
      set("ep" + i + "version",2);
   }
   i++;
}
if(chatVersion == undefined)
{
   chatVersion = 2;
}
if(charVersion == undefined)
{
   charVersion = 2;
}
if(spiderVersion == undefined)
{
   spiderVersion = 2;
}
if(battleVersion == undefined)
{
   battleVersion = 2;
}
if(worldVersion == undefined)
{
   worldVersion = 2;
}
if(mGame1Version == undefined)
{
   mGame1Version = 2;
}
if(mGame2Version == undefined)
{
   mGame2Version = 2;
}
if(mGame3Version == undefined)
{
   mGame3Version = 2;
}
if(mGame4Version == undefined)
{
   mGame4Version = 2;
}
if(mGame5Version == undefined)
{
   mGame5Version = 2;
}
if(mGame6Version == undefined)
{
   mGame6Version = 2;
}
if(GAMEDEBUG == undefined)
{
   GAMEDEBUG = true;
}
if(userLang == undefined || userLang == "")
{
   userLang = "EN";
}
if(xmlNbr == undefined)
{
   xmlNbr = "01";
}
FirstEnter = true;
inWorld = undefined;
inCamp = false;
_quality = "MEDIUM";
sVol = new Sound();
musicMix = clampMix(musicVolume,100);
effectMix = clampMix(effectVolume,100);
musicLabels = {theme:1,music1:1,music2:1,music3:1,area1:1,area2:1,area3:1,area4:1,area5:1,area6:1,battleMonster:1,battleInvectid:1,battleRider:1,battleSystem:1,winner:1,stopAllMusic:1};
trace("GAMEDEBUG = " + GAMEDEBUG);
if(!GAMEDEBUG)
{
   currentV = 50;
}
else
{
   currentV = 0;
}
setNewVolume(currentV,false);
rewardAccess = false;
idleFrq = 200;
stop();
