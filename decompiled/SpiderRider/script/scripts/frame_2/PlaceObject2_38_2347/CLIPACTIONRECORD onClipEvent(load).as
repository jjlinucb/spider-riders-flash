onClipEvent(load){
   function drawWindow(msg)
   {
      trace("LOAD critic drawWindow");
      openWindow();
   }
   function openWindow()
   {
      trace("LOAD critic openWindow");
      _visible = false;
   }
   function closeWindow()
   {
      _visible = false;
      gotoAndStop(1);
   }
}
