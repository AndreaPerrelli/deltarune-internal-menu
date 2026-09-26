function scr_im_wall(_x,_y,_obj) {return !scr_im_on("noclip") && place_meeting(_x,_y,_obj);}
function scr_im_setparty(_susie,_ralsei,_noelle) {
    scr_losechar();with(obj_caterpillarchara)instance_destroy();
    var chars=[];if(_susie)array_push(chars,2);if(_ralsei)array_push(chars,3);if(_noelle && global.im.maxchar>=4)array_push(chars,4);
    for(var j=0;j<array_length(chars);j++){
        scr_getchar(chars[j]);
        if(instance_exists(obj_mainchara))scr_makecaterpillar(obj_mainchara.x,obj_mainchara.y,chars[j],j);
    }
}
function scr_im_give(_id,_kind){
    noroom=0;
    if(_kind=="item")scr_itemget(_id);
    if(_kind=="weapon")scr_weaponget(_id);
    if(_kind=="armor")scr_armorget(_id);
    if(_kind=="key")scr_keyitemget(_id);
}
function scr_im_startbattle(_enc) { scr_battle(_enc,0,-1,-1,-1); }
