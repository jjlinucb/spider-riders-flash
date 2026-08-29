function loadFriendDesc(fName)
{
   var _loc1_ = fName;
   for(var _loc2_ in fArr)
   {
      if(fArr[_loc2_][0] == _loc1_)
      {
         return fArr[_loc2_][1];
      }
   }
}
function removeFriend(fName)
{
   var _loc1_ = fName;
   for(var _loc2_ in fArr)
   {
      if(fArr[_loc2_][1].Name == _loc1_)
      {
         fArr[_loc2_][0].removeMovieClip();
         fArr.splice(_loc2_,1);
         break;
      }
   }
}
function hideFriendAction(fName)
{
   for(var i in fArr)
   {
      if(fArr[i][1].Name == fName)
      {
         var newFriend = eval("root.scrnClip.friend" + fName);
         if(newFriend != undefined)
         {
            newFriend.bubble.hideBubble();
            newFriend.action.hideAction();
         }
      }
      break;
   }
}
function setChatMessage(fName, fMsg, eType)
{
   if(fName == root.playerStats.Name)
   {
      root.bubble.hideBubble();
      root.emptyClip.char.action.hideAction();
      if(fMsg == 0)
      {
         root.emptyClip.char.action.drawAction(eType);
      }
      else
      {
         root.bubble.drawBubble(fMsg,eType);
      }
   }
   else
   {
      for(var i in fArr)
      {
         if(fArr[i][1].Name == fName)
         {
            var newFriend = eval("root.scrnClip.friend" + fName);
            if(newFriend != undefined)
            {
               newFriend.bubble.hideBubble();
               newFriend.action.hideAction();
               fMsg != 0 ? newFriend.bubble.drawBubble(fMsg,eType) : newFriend.action.drawAction(eType);
            }
            break;
         }
      }
   }
}
function cloneFriend(fDesc, fX, fY)
{
   var _loc2_ = fDesc;
   var _loc1_;
   if(root.fArr.length < root.maxFriendsShown)
   {
      if(_loc2_.Name != root.playerStats.Name)
      {
         _loc1_ = scrnClip.createEmptyMovieClip("friend" + _loc2_.Name,root.getNewDepth());
         _loc1_.loadMovie("friends_2.swf");
         root.fArr.push([_loc1_,_loc2_]);
         _loc1_._x = fX;
         _loc1_._y = fY;
         _loc1_._visible = friendsVisibility;
      }
   }
}
function setTradeScreen(p2Name)
{
   root.tradeWindow.gotoAndStop("loading");
   root.callPrivateEvent(7,root.playerStats.Name,p2Name);
}
function setBattleScreen(p2Name)
{
   root.tradeWindow.gotoAndStop("loading");
   root.callPrivateEvent(8,root.playerStats.Name,p2Name);
}
function setMGameScreen(p2Name, gameID)
{
   root.tradeWindow.gotoAndStop("loading");
   root.callPrivateEvent(gameID,root.playerStats.Name,p2Name);
}
function callMatchMaking(mGameID)
{
   nr_nc.call("setMatchMaking",null,mGameID,root.worldScrn,root.worldSO);
}
function callPrivateEvent(mGameID, name1, name2)
{
   nr_nc.call("setPrivateEvent",null,mGameID,root.worldScrn,root.worldSO,name1,name2);
}
function callKillGame()
{
   root.callChangeStatus(root.worldScrn);
   delete root.gameSO;
   nr_nc.call("killGame",null);
}
function callInvectidKill(arrName, arrID)
{
   nr_nc.call("setInvectidKill",null,arrName,arrID);
}
function callUnsetDates()
{
   nr_nc.call("unsetDates");
}
function callUnsetClients()
{
   nr_nc.call("unsetClients");
}
function cleanDescObj()
{
   if(root.playerStats.guild == 0)
   {
      return {typeSex:root.typeSex,typeHair:root.typeHair,typeEyes:root.typeEyes,typeSkin:root.typeSkin,g:""};
   }
   return {typeSex:root.typeSex,typeHair:root.typeHair,typeEyes:root.typeEyes,typeSkin:root.typeSkin,g:root.playerStats.guild};
}
function ease(clip, ep, ep2)
{
   var _loc1_ = clip;
   var _loc2_ = this;
   var t = 0;
   var d = 0;
   d += _loc1_._x <= ep ? Math.floor((ep - _loc1_._x) / 4) : Math.floor((_loc1_._x - ep) / 4);
   d += _loc1_._y <= ep2 ? Math.floor((ep2 - _loc1_._y) / 4) : Math.floor((_loc1_._y - ep2) / 4);
   var sp = _loc1_._x;
   var sp2 = _loc1_._y;
   var cp = ep - sp;
   var cp2 = ep2 - sp2;
   _loc1_.onEnterFrame = function()
   {
      var _loc1_ = this;
      _loc1_._x = Math.linearTween(t,sp,cp,d);
      _loc1_._y = Math.linearTween(t,sp2,cp2,d);
      if(++t > d)
      {
         _loc1_._x = ep;
         _loc1_._y = ep2;
         delete _loc1_.onEnterFrame;
      }
   };
}
function initNetConnection()
{
   var tempReactFct = function()
   {
      root.charWindow.drawWindow();
   };
   nr_nc = new NetConnection();
   nr_nc.onStatus = function(info)
   {
      var _loc1_ = info;
      if(_loc1_.code == "NetConnection.Connect.Success")
      {
         nr_nc.call("login",null,playerStats.Name,root.cleanDescObj(),"none",root.uDay,root.uMonth,root.uYear,root.uId,root.uState);
      }
      else if(_loc1_.code == "NetConnection.Connect.Rejected")
      {
         root.textWindow.drawWindow([getInsName("nameError",parseMultiConnect) + _loc1_.code + " - " + _loc1_.application.errorMsg],0,tempReactFct);
      }
      else if(_loc1_.code == "NetConnection.Connect.Failed" || _loc1_.code == "NetConnection.Connect.BadVersion")
      {
         if(!secondTry)
         {
            secondTry = true;
            killNetConnection();
            initNetConnection();
         }
         else
         {
            root.textWindow.drawWindow([getInsName("nameError",parseMultiConnect) + _loc1_.code + " - " + _loc1_.description],0,tempReactFct);
         }
      }
      else
      {
         root.textWindow.drawWindow([getInsName("nameError",parseMultiConnect) + _loc1_.code + " - " + _loc1_.description],0,tempReactFct);
         root.userSO.close();
         root.gameSO.close();
         delete root.userSO;
         delete root.gameSO;
      }
   };
   nr_nc.testLoginResult = function(msgStatus, crntEvent)
   {
      var _loc1_ = msgStatus;
      var _loc2_;
      if(_loc1_ == "userLimitExceeded")
      {
         root.connectIcon.gotoAndPlay("broken");
         _loc2_ = function()
         {
            root.zoneNbr++;
            if(root.zoneNbr > 8)
            {
               root.zoneNbr = 1;
            }
            root.gotoAndPlay("remote");
         };
         root.textWindow.drawWindow([getInsName("nameErrLmt",parseMultiConnect)],0,_loc2_);
      }
      else if(_loc1_ == "userAlreadyConnected")
      {
         root.connectIcon.gotoAndPlay("broken");
         root.textWindow.drawWindow([getInsName("nameError",parseMultiConnect) + ssUserLogin + getInsName("nameErrUsd",parseMultiConnect)],0,tempReactFct);
      }
      else if(_loc1_ == "userConnected")
      {
         root.worldSO = "1";
         root.connectIcon.gotoAndPlay("success");
         root.crntEvent = crntEvent;
         trace("id = " + root.crntEvent.id);
         trace("state = " + root.crntEvent.state);
         initUserSO();
         nr_nc.call("getZoneArr",null);
         root.gotoAndStop("chat");
      }
   };
   nr_nc.pingCall = function()
   {
      nr_nc.call("pingCall",null);
   };
   nr_nc.acceptWarp = function()
   {
      root.tempWarpFct();
      root.tempWarpFct2();
   };
   nr_nc.prepareTrade = function()
   {
      root.tradeWindow.gotoAndStop("loading");
   };
   nr_nc.unsetTrade = function()
   {
      root.textWindow.drawWindow([getInsName("userConnectError",parseMultiConnect)],0,null);
      root.tradeWindow.gotoAndStop(1);
   };
   nr_nc.initGameSO = function(nameSO, playerDesc1, playerDesc2, gameID)
   {
      root.initGameSO(nameSO,playerDesc1,playerDesc2,gameID);
   };
   nr_nc.setZoneArr = function(arr1, arr2, arr31, arr32, arr41, arr42, arr5, arr6)
   {
      trace("GOT ZONE ARR ON INIT");
      trace("_1: " + arr1);
      trace("_2: " + arr2);
      trace("_3_1: " + arr31);
      trace("_3_2: " + arr32);
      trace("_4_1: " + arr41);
      trace("_4_2: " + arr42);
      trace("_5: " + arr5);
      trace("_6: " + arr6);
      zone1Arr = arr1;
      zone2Arr = arr2;
      zone3Arr1 = arr31;
      zone3Arr2 = arr32;
      zone4Arr1 = arr41;
      zone4Arr2 = arr42;
      zone5Arr = arr5;
      zone6Arr = arr6;
   };
   if(!secondTry)
   {
      trace(serverLink3 + "/room_" + root.zoneNbr);
      if(GAMEDEBUG)
      {
         nr_nc.connect(serverLink3 + "/room_" + root.zoneNbr,root.cleanDescObj());
      }
      else
      {
         nr_nc.connect(serverLink + "/room_" + root.zoneNbr,root.cleanDescObj());
      }
   }
   else
   {
      nr_nc.connect(serverLink2 + "/room_" + root.zoneNbr,root.cleanDescObj());
   }
}
function initUserSO(soFct)
{
   userSO = SharedObject.getRemote("userSO" + root.worldSO,nr_nc.uri,false);
   userSO.onSync = function(userArray)
   {
      var i = 0;
      while(i < userArray.length)
      {
         switch(userArray[i].code)
         {
            case "clear":
               uArr = new Array();
               break;
            case "change":
               var fObj = eval("this.data." + userArray[i].name);
               trace("///");
               trace("newFriend: " + fObj.n);
               trace("newFriend\'s guild: " + fObj.g);
               trace("crnScren: " + fObj.s);
               trace("myScrn: " + root.worldScrn);
               var newFriend = eval("root.scrnClip.friend" + fObj.n);
               trace(newFriend);
               if(fObj.s == root.worldScrn && fObj.n != root.playerStats.Name)
               {
                  if(newFriend != undefined || newFriend != "")
                  {
                     newFriend._visible = friendsVisibility;
                     var descFlag = false;
                     for(var n in root.fArr)
                     {
                        if(root.fArr[n][1].Name == fObj.n)
                        {
                           if(root.fArr[n][1].typeSex == fObj.sx && root.fArr[n][1].typeSkin == fObj.sk && root.fArr[n][1].typeHair == fObj.h && root.fArr[n][1].g == fObj.g)
                           {
                              descFlag = true;
                              break;
                           }
                        }
                     }
                     if(descFlag)
                     {
                        root.ease(newFriend,fObj.x,fObj.y);
                     }
                     else
                     {
                        removeFriend(fObj.n);
                        var newFDesc = {typeSex:fObj.sx,Name:fObj.n,typeEyes:fObj.e,typeSkin:fObj.sk,typeHair:fObj.h,g:fObj.g};
                        root.cloneFriend(newFDesc,fObj.x,fObj.y);
                     }
                  }
                  else
                  {
                     var newFDesc = {typeSex:fObj.sx,Name:fObj.n,typeEyes:fObj.e,typeSkin:fObj.sk,typeHair:fObj.h,g:fObj.g};
                     root.cloneFriend(newFDesc,fObj.x,fObj.y);
                  }
               }
               else if(newFriend != undefined)
               {
                  removeFriend(fObj.n);
               }
               uArr.push(fObj);
               break;
            case "delete":
               var j = 0;
               while(j < uArr.length)
               {
                  if(uArr[j].n == userArray[i].name)
                  {
                     uArr.splice(j,1);
                     break;
                  }
                  j++;
               }
         }
         i++;
      }
   };
   userSO.removeFriend = function(fName)
   {
      root.removeFriend(fName);
   };
   userSO.hideFriendAction = function(fName)
   {
      root.hideFriendAction(fName);
   };
   userSO.setChatMessage = function(fName, fMsg, eType)
   {
      var _loc1_ = eType;
      var _loc2_ = fMsg;
      if(_loc2_ != "")
      {
         root.setChatMessage(fName,_loc2_,_loc1_);
      }
      else if(_loc1_ > 0)
      {
         root.setChatMessage(fName,_loc2_,_loc1_);
      }
   };
   userSO.updateInvectid = function(arrName, arrID, nbrUpdate)
   {
      var _loc1_ = nbrUpdate;
      var _loc2_ = arrName;
      var _loc3_ = arrID;
      if(_loc2_ == "1")
      {
         zone1Arr[_loc3_][1] = _loc1_;
      }
      else if(_loc2_ == "2")
      {
         zone2Arr[_loc3_][1] = _loc1_;
      }
      else if(_loc2_ == "31")
      {
         zone3Arr1[_loc3_][1] = _loc1_;
      }
      else if(_loc2_ == "32")
      {
         zone3Arr2[_loc3_][1] = _loc1_;
      }
      else if(_loc2_ == "41")
      {
         zone4Arr1[_loc3_][1] = _loc1_;
      }
      else if(_loc2_ == "42")
      {
         zone4Arr2[_loc3_][1] = _loc1_;
      }
      else if(_loc2_ == "5")
      {
         zone5Arr[_loc3_][1] = _loc1_;
      }
      else if(_loc2_ == "6")
      {
         zone6Arr[_loc3_][1] = _loc1_;
      }
      game[_loc2_ + "_" + _loc3_].counter.outputTxt.text = _loc1_;
   };
   userSO.setZoneArr = function(arr1, arr2, arr31, arr32, arr41, arr42, arr5, arr6)
   {
      trace("GOT ZONE ARR");
      trace("_1: " + arr1);
      trace("_2: " + arr2);
      trace("_3_1: " + arr31);
      trace("_3_2: " + arr32);
      trace("_4_1: " + arr41);
      trace("_4_2: " + arr42);
      trace("_5: " + arr5);
      trace("_6: " + arr6);
      zone1Arr = arr1;
      zone2Arr = arr2;
      zone3Arr1 = arr31;
      zone3Arr2 = arr32;
      zone4Arr1 = arr41;
      zone4Arr2 = arr42;
      zone5Arr = arr5;
      zone6Arr = arr6;
   };
   if(!userSO.connect(nr_nc))
   {
      var tempReactFct = function()
      {
         root.charWindow.drawWindow();
      };
      root.textWindow.drawWindow([getInsName("connectError",parseMultiConnect)],0,tempReactFct);
   }
   else
   {
      soFct();
      delete soFct;
   }
}
function killNetConnection()
{
   trace("KILL NET CONNECTION");
   gameSO.close();
   delete gameSO;
   userSO.close();
   delete userSO;
   delete nr_nc;
   clearInterval(root.intrvlSwitch);
}
function initGameSO(nameSO, playerDesc1, playerDesc2, gameID)
{
   var _loc1_ = gameID;
   var _loc3_ = playerDesc1;
   root.chatWindow.gotoAndStop("hide");
   root.callChangeStatus("busy");
   var _loc2_ = new Array(_loc3_,playerDesc2);
   _loc3_.n == root.playerStats.Name ? root.mGameWindow.drawGame(playerDesc2.n) : root.mGameWindow.drawGame(_loc3_.n);
   root["miniGame" + _loc1_].setGameDesc(_loc2_);
   gameSO = SharedObject.getRemote(nameSO,nr_nc.uri,false);
   if(_loc1_ == 1)
   {
      gameSO.playerDisconnect = function()
      {
         root.miniGame1.disConnect();
      };
      gameSO.sendAnim = function(playerID, charID, typeAnim, mWidth, pScore)
      {
         root.miniGame1.setAnim(playerID,charID,typeAnim,mWidth,pScore);
      };
      gameSO.startGame = function()
      {
         root.tradeWindow.gotoAndStop(1);
         root.mGameWindow.closeWindow();
         root.miniGame1.drawGame("multi");
      };
   }
   else if(_loc1_ == 2)
   {
      gameSO.playerDisconnect = function()
      {
         root.miniGame2.disConnect();
      };
      gameSO.setEndStat = function(obj)
      {
         root.miniGame2.throwEndGame(obj);
      };
      gameSO.startGame = function()
      {
         root.tradeWindow.gotoAndStop(1);
         root.mGameWindow.closeWindow();
         root.miniGame2.drawGame("multi");
      };
      gameSO.sendEvent = function(typeEvent, ranPoint)
      {
         root.miniGame2.launchEvent(typeEvent,ranPoint);
      };
      gameSO.removeEvent = function(Name)
      {
         root.miniGame2.removeEvent(Name);
      };
      gameSO.sendPosition = function(Name, nx, ny, nr, ng, nl)
      {
         if(Name != root.playerStats.Name)
         {
            root.miniGame2.setRemotePosition(Name,nx,ny,nr,ng,nl);
         }
      };
      gameSO.initMultiGame = function(gameTrack, ranSpider)
      {
         root.miniGame2.setMultiGame(gameTrack,ranSpider);
      };
      gameSO.setStartFlag = function(crntNbr)
      {
         root.miniGame2.setStartFlag(crntNbr);
      };
      gameSO.setEndScreen = function()
      {
         root.miniGame2.clearData(false);
      };
   }
   else if(_loc1_ == 3)
   {
      gameSO.playerDisconnect = function()
      {
         root.miniGame3.disConnect();
      };
      gameSO.startGame = function()
      {
         root.tradeWindow.gotoAndStop(1);
         root.mGameWindow.closeWindow();
         root.miniGame3.drawGame("multi");
      };
      gameSO.updateStat = function(score, playerName)
      {
         root.miniGame3.updateScore(score,playerName);
      };
      gameSO.playerLose = function(playerName)
      {
         root.miniGame3.playerLose(playerName);
      };
      gameSO.updateChar = function(action, playerName, score)
      {
         root.miniGame3.updateChar(action,playerName,score);
      };
      gameSO.sendChar = function(char, playerName)
      {
         root.miniGame3.showChar(char,playerName);
      };
      gameSO.sendCoor = function(newX, newY, arrowThrow, playerName)
      {
         root.miniGame3.updateFriend(newX,newY,arrowThrow,playerName);
      };
      gameSO.throwEndGame = function(obj1)
      {
         root.miniGame3.setWinner(obj1);
      };
      gameSO.sendScene = function(playerName, bkg)
      {
         root.miniGame3.setScene(playerName,bkg);
      };
   }
   else if(_loc1_ == 7)
   {
      root.tradeWindow.setGameDesc(_loc2_);
      gameSO.switchTurn = function(switchDesc)
      {
         root.tradeWindow.loadSwitchTurn(switchDesc);
      };
      gameSO.answerOffer = function(answer)
      {
         root.tradeWindow.loadAnswerOffer(answer);
      };
      gameSO.startGame = function()
      {
         root.tradeWindow.drawGame();
      };
      gameSO.setTradersCards = function(p2Name, cardsArr)
      {
         if(p2Name != root.playerStats.Name)
         {
            root.tradeWindow.setTradersCards(p2Name,cardsArr);
         }
      };
      gameSO.confirmTradeStart = function(p2Name)
      {
         root.tradeWindow.confirmTradeStart(p2Name);
      };
      gameSO.playerDisconnect = function()
      {
         root.tradeWindow.popWait.drawMsg(getInsName("prtnrDiscon",parseMultiConnect));
      };
      gameSO.quitModule = function(p2Name)
      {
         if(p2Name != root.playerStats.Name)
         {
            root.tradeWindow.popWait.drawMsg(getInsName("opponentQuit",parseMultiConnect));
         }
      };
   }
   else if(_loc1_ == 8)
   {
      root.battleMulti.setGameDesc(_loc2_);
      root.battleMulti.drawBattle();
      gameSO.initTurn = -1;
      gameSO.startGame = function()
      {
         root.battleMulti.drawBattle();
      };
      gameSO.setBattleCards = function(p2Name, cardsArr, objAvatar, SpiderName, objSpiderStats, objSpiderDesc)
      {
         if(p2Name != root.playerStats.Name)
         {
            root.battleMulti.setBattleCards(p2Name,cardsArr,objAvatar,SpiderName,objSpiderStats,objSpiderDesc);
         }
      };
      gameSO.showDicesFGSO = function(dicesRef, p2Name)
      {
         if(p2Name != root.playerStats.Name)
         {
            root.battleMulti.mainGame_mc.showDicesShown(dicesRef);
         }
      };
      gameSO.playerAttack = function(p2Name, nDices, nDefPlus, strCardIDPlayer, strCardsToKill)
      {
         if(p2Name != root.playerStats.Name)
         {
            root.battleMulti.mainGame_mc.OpponentAttackFGSO(nDices,nDefPlus,strCardIDPlayer,strCardsToKill);
         }
      };
      gameSO.playerDisconnect = function()
      {
         root.battleMulti.disconnect();
      };
      gameSO.updateCardDeck = function(p2Name, bMyDeckToUpdate, strCardID, strCardIDInDeck)
      {
         if(p2Name != root.playerStats.Name)
         {
            root.battleMulti.mainGame_mc.updateDeckFGSO(bMyDeckToUpdate,strCardID,strCardIDInDeck,null,true);
         }
      };
      gameSO.playerRetreat = function(p2Name)
      {
         if(p2Name != root.playerStats.Name)
         {
            root.battleMulti.OpponentHaveRetreated();
         }
      };
      gameSO.playerNoMoreCard = function(p2Name)
      {
         if(p2Name != root.playerStats.Name)
         {
            root.battleMulti.OpponentNoMoreCard();
         }
      };
      gameSO.AccuseReceptionInit = function(p2Name)
      {
         if(p2Name != root.playerStats.Name)
         {
            root.battleMulti.mainGame_mc.AccuseReceptionInit();
         }
      };
      gameSO.AccuseReceptionAttack = function(p2Name)
      {
         if(p2Name != root.playerStats.Name)
         {
            root.battleMulti.mainGame_mc.AccuseReceptionAttack();
         }
      };
   }
   if(!gameSO.connect(nr_nc))
   {
      root.textWindow.drawWindow([getInsName("connectError",parseMultiConnect)],0,tempReactFct);
   }
}
function getNewDepth()
{
   ldepth++;
   ldepth %= 150;
   return 11000 + ldepth;
}
function callMovement(newX, newY)
{
   trace("callMovement");
   nr_nc.call("setMove",null,root.playerStats.Name,newX,newY,root.worldSO);
}
function callWarp(newScrn, newX, newY, newNameSO)
{
   googleAnalytic("javascript:urchinTracker(\'/arachna/" + newScrn + "\');");
   root.emptyClip.char.bubble.hideBubble();
   root.emptyClip.char.action.hideAction();
   for(var i in root.fArr)
   {
      delete root.fArr[i][0].onEnterFrame;
      root.fArr[i][0].removeMovieClip();
   }
   root.fArr = new Array();
   root.criticMsgWindow.drawWindow();
   root.tempWarpFct = function()
   {
      var _loc1_;
      for(var i in root.uArr)
      {
         if(root.uArr[i].s == root.worldScrn)
         {
            _loc1_ = {typeSex:root.uArr[i].sx,Name:root.uArr[i].n,typeEyes:root.uArr[i].e,typeSkin:root.uArr[i].sk,typeHair:root.uArr[i].h,g:root.uArr[i].g};
            root.cloneFriend(_loc1_,root.uArr[i].x,root.uArr[i].y);
         }
      }
      if(newNameSO == undefined)
      {
         root.criticMsgWindow.closeWindow();
         delete root.tempWarpFct;
         delete root.tempWarpFct2;
      }
      else
      {
         root.callSwapSO(newNameSO);
         root.tempWarpFct2 = function()
         {
            root.initUserSO();
            root.criticMsgWindow.closeWindow();
            delete root.tempWarpFct2;
         };
         delete root.tempWarpFct;
      }
   };
   nr_nc.call("warp",null,root.playerStats.Name,newScrn,newX,newY,root.worldSO);
}
function callSwapSO(newNameSO)
{
   for(var _loc1_ in root.fArr)
   {
      delete root.fArr[_loc1_][0].onEnterFrame;
      root.fArr[_loc1_][0].removeMovieClip();
   }
   root.fArr = new Array();
   userSO.close();
   delete userSO;
   root.uArr = new Array();
   nr_nc.call("swapSO",null,root.playerStats.Name,root.worldSO,newNameSO);
   root.worldSO = String(newNameSO);
}
function callChangeDesc()
{
   nr_nc.call("changeDesc",null,root.playerStats.Name,root.cleanDescObj(),root.worldSO);
}
function callChangeStatus(scrn)
{
   nr_nc.call("changeWorldStatus",null,scrn,root.worldSO);
}
function completeCardTrade(tradeCardArr)
{
   var _loc2_ = tradeCardArr;
   var _loc1_;
   for(var i in _loc2_[0])
   {
      _loc1_ = false;
      for(var _loc3_ in root.playerStats.card)
      {
         if(!_loc1_)
         {
            if(Number(_loc2_[0][i]) == Number(root.playerStats.card[_loc3_].id))
            {
               root.playerStats.card.splice(_loc3_,1);
               _loc1_ = true;
            }
         }
      }
   }
   root.genCardsArr = _loc2_[1];
   root.cardGenFct = function()
   {
      var _loc1_ = root.genCardsArr.shift();
      if(root.playerStats.card.length < 100)
      {
         root.playerStats.card.push({id:Number(_loc1_),deck:0,spc:0});
         if(root.genCardsArr.length > 0)
         {
            root.cardGenFct();
         }
         else
         {
            delete root.genCardsArr;
            delete root.cardGenFct;
            root.setDeckOrder();
            root.updateAllCards();
         }
      }
      else
      {
         root.swapCardWindow.drawWindow(Number(_loc1_));
      }
   };
   root.cardGenFct();
}
function hideFriend(doHideFlag)
{
   friendsVisibility = doHideFlag != true ? true : false;
   for(var _loc1_ in root.fArr)
   {
      root.fArr[_loc1_][0]._visible = friendsVisibility;
   }
}
_global.DEBUG_ONLINE = true;
ldepth = 0;
maxFriendsShown = 25;
secondTry = false;
fArr = new Array();
zone1Arr = new Array();
zone2Arr = new Array();
zone3Arr1 = new Array();
zone3Arr2 = new Array();
zone4Arr1 = new Array();
zone4Arr2 = new Array();
zone5Arr = new Array();
zone6Arr = new Array();
Math.linearTween = function(t, b, c, d)
{
   return c * t / d + b;
};
