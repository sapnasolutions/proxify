$(document).ready(function(){

	var left	= 0,
		top		= 0,
		sizes	= { invisible: { width:200, height:200 }, webpage:{ width:$('body').width(), height:$('body').height() } },
		webpage	= $('body'),
		offset	= { left: webpage.offset().left, top: webpage.offset().top },
		invisible	= $('#invisible'),
		suppressor = $('.surppressor');

	if(navigator.userAgent.indexOf('Chrome')!=-1)
	{
		invisible.addClass('chrome');
	}
	
	webpage.mousemove(function(e){

		left = (e.pageX-offset.left);
		top = (e.pageY-offset.top);

		if(invisible.is(':not(:animated):hidden')){
			webpage.trigger('mouseenter');
		}

		if(left<0 || top<0 || left > sizes.webpage.width || top > sizes.webpage.height)
		{
			if(!invisible.is(':animated')){
				webpage.trigger('mouseleave');
			}
			return false;
		}

		invisible.css({
			left				: left - sizes.invisible.width/2,
			top					: top - sizes.invisible.height/2,
			backgroundPosition	: '-'+(1.6*left)+'px -'+(1.5*top)+'px'
		});
		
	}).mouseleave(function(){
		invisible.stop(true,true).fadeOut('fast');
	}).mouseenter(function(){
		invisible.stop(true,true).fadeIn('fast');
	});
	
	suppressor.mouseenter(function(){
		webpage.trigger('mouseleave');
		invisible.addClass('suppressed');
	}).mouseleave(function(){
		webpage.trigger('mouseenter');
		invisible.removeClass('suppressed');
	});
	
	$('h1 em').effect('pulsate', 6000);
	
	/*
	$('#form-wrapper').mouseenter(function(){
		//if (! $('#form-wrapper').hasClassName('suppressed')) {
			growForm = $('#form-wrapper').animate({width:'+=200px', height:'+=30px'},400, function(){
				$('#url').css('font-size:20px');
				$('#url').select();
			});
		//}
	});
	
	$('#form-wrapper').mouseleave(function(){
		$('#url').blur();
		shrinkForm = $('#form-wrapper').animate({width:'-=200px', height:'-=30px'},400);
	});
	*/
});
