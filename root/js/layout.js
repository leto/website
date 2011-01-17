/***************************/
// layout functions
// author: Abigail Cabunoc
// abigail.cabunoc@oicr.on.ca      
/***************************/

//The layout methods

    function columns(leftWidth, rightWidth, noUpdate){
      if(leftWidth>99){
        $jq("#widget-holder").children(".sortable").css('min-height', '0');
      }else{
        $jq("#widget-holder").children(".sortable").css('min-height', '5em');
      }
      $jq("#widget-holder").children(".left").css("width",leftWidth + "%");
      if(rightWidth==0){rightWidth=100;}
      $jq("#widget-holder").children(".right").css("width",rightWidth + "%");
      if(!noUpdate){ updateLayout(); }
    }

    function deleteLayout(layout){
      var $class = $jq("#widget-holder").attr("class");
      $jq.get("/rest/layout/" + $class + "/" + layout + "?delete=1");
      $jq("div.columns ul div li#layout-" + layout).remove();
    }

    function setLayout(layout){
      var $class = $jq("#widget-holder").attr("class");
      $jq.get("/rest/layout/" + $class + "/" + layout, function(data) {
          var nodeList = data.childNodes[0].childNodes;
          var len = nodeList.length;
          for(i=0; i<len; i++){
            var node = nodeList.item(i);
            if(node.nodeName == "data"){
              var leftList = node.attributes.getNamedItem('left').nodeValue.split(',');
              var rightList = node.attributes.getNamedItem('right').nodeValue.split(',');
              var leftWidth = node.attributes.getNamedItem('leftWidth').nodeValue;
              resetLayout(leftList, rightList, leftWidth);
            }
          }
        }, "xml");
    }

    function newLayout(layout){
      updateLayout(layout, function() {
        $jq(".list-layouts").load("/rest/layout_list/" + $jq(".list-layouts").attr("type"), function(response, status, xhr) {
            if (status == "error") {
                var msg = "Sorry but there was an error: ";
                $jq(".list-layouts").html(msg + xhr.status + " " + xhr.statusText);
              }
            });
          });
      return false;
    }
    
    function updateURLHash (left, right, leftWidth) {
      var l = "l[" + left.join(',') + "],";
      var r = "r[" + right.join(',') + "],";
      var w = "w[" + leftWidth + "]";
      location.hash = l  + r  + w;
      return;
    }
    
    function readHash() {

      var h = decodeURI(location.hash);
      var left = [];
      var right = [];
      var findL = h.match(/l\[([^[\]]*)\]/);
      var findR = h.match(/r\[([^[\]]*)\]/);
      var findW = h.match(/w\[([^[\]]*)\]/);

      var a = getAnchor(h);
      var w = (findW && findW.length>0) ? findW[1] : false;

      var l = findL[1].split(',');
      var r = findR[1].split(',');
      
      var reset = compare(l, r, w);
      if(reset){
        resetLayout(l, r, w);
        goToAnchor(a);
      }
    }
    
    function getAnchor(h){
      var findA = h.match(/a\[([^[\]]*)\]/);
      return (findA && findA.length>0) ? findA[1] : false;
    }
    
    function goToAnchor(anchor){
      document.getElementById(anchor).scrollIntoView(true);
    }
    
    function compare(l, r, w) {
      var holder =  $jq("#widget-holder");
      var left = holder.children(".left").children(".visible")
                        .map(function() { return this.id;})
                        .get();
      var right = holder.children(".right").children(".visible")
                        .map(function() { return this.id;})
                        .get();
      var leftWidth = getLeftWidth(holder);
      var diff = leftWidth - w;
      if((left.length != l.length) || (right.length != r.length)){
        return true;
      }else if((diff > 5)||(diff < -5)){
        return true;
      }else {
          var i = 0;
          for(i=0;i<left.length;i++){
            if(left[i] != l[i]){
              return true;
            }
          }
          i=0;
          for(i=0;i<right.length;i++){
            if(right[i] != r[i]){
              return true;
            }
          }
      }
      return false;
    }

    function updateLayout(layout, callback){
      l = 'default';
      if((typeof layout) == 'string'){
        l = escape(layout); 
      }

      var holder =  $jq("#widget-holder");
      var $class = holder.attr("class");
      var left = holder.children(".left").children(".visible")
                        .map(function() { return this.id;})
                        .get();
      var right = holder.children(".right").children(".visible")
                        .map(function() { return this.id;})
                        .get();
      var leftWidth = getLeftWidth(holder);
      updateURLHash(left, right, leftWidth);
      $jq.post("/rest/layout/" + $class + "/" + l, { 'left[]': left, 'right[]' : right, 'leftWidth':leftWidth }, function(){
        if(callback){ callback(); }
      });

    }

    function getLeftWidth(holder){
      var totWidth = parseFloat(holder.css("width"));
//       var leftWidth = parseFloat(holder.children(".left").css("width"));
      var leftWidth = (parseFloat(holder.children(".left").css("width"))/totWidth)*100;
      return Math.round(leftWidth);
    }

    function resetLayout(leftList, rightList, leftWidth){
      $jq("div#navigation").children("ul").children("li").removeClass("ui-selected");
      $jq("#widget-holder").children().children("li").removeClass("visible");

      columns(leftWidth, (100-leftWidth), 1);
      for(widget in leftList){
        var widget_name = leftList[widget];
        if(widget_name.length > 0){
          var nav = $jq("#nav-" + widget_name);
          var content = "div#" + widget_name + "-content";
          nav.attr("load", 0);
          openWidget(widget_name, nav, content, ".left");
        }
      }
      for(widget in rightList){
        var widget_name = rightList[widget];
        if(widget_name.length > 0){
          var nav = $jq("#nav-" + widget_name);
          var content = "div#" + widget_name + "-content";
          openWidget(widget_name, nav, content, ".right");
        }
      }
      updateLayout();
    }






$jq(function() {

    var $sidebar   = $jq("#navigation"),
        $window    = $jq(window),
        offset     = 0,
        loadcount  = 0,
        at_default = -45;

    $window.scroll(function() {
      if($sidebar.offset()){
        if(!offset){offset = $sidebar.offset().top;}

        var bottomPos = $sidebar.parent().height() - $sidebar.outerHeight();
        if( bottomPos < at_default )
            bottomPos = at_default;
        var objBiggerThanWindow = $sidebar.outerHeight() < $window.height();
        if (objBiggerThanWindow){
          if ($window.scrollTop() > offset) {
              var newpos = $window.scrollTop() - offset + 10 + at_default;
              if (newpos > bottomPos)
                  newpos = bottomPos;
                  $sidebar.stop().css(
                  'margin-top', newpos
              );
          } else {
              $sidebar.stop().css(
                  'margin-top', at_default
              );
          }
        }
      } 
      var results    = $jq("#results"); //load inside so we can catch the results loaded by ajax calls
      if(results.offset() && loadcount < 2){

        var rHeight = results.height() + results.offset().top;
        var rBottomPos = rHeight - ($window.height() + $window.scrollTop())
        if(rBottomPos < 400) {
          results.children(".load-results").trigger('click');
          loadcount++;
        }
      }

    });

});