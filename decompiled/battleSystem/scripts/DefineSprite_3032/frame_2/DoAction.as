if(root.inWorld == true)
{
   gotoAndStop(1);
}
else
{
   protectBtn.useHandCursor = false;
   this.swapDepths(1000000);
   if(root.playerStats.mission > 1)
   {
      gotoAndStop("HIDE_TUTORIAL");
   }
}
