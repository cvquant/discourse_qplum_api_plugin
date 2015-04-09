Discourse.ScoreButton = Discourse.ButtonView.extend({
	text: 'Score',
	title: 'Display the score of the user',
	score: 0,
	
	shouldRerender: Discourse.View.renderIfChanged('this.text'),

	click: function(){		
		this.updateScore();			
	},


	renderIcon: function(buffer){
		buffer.push("<i class='icon icon-score-sign'></i>");
	},

	updateScore: function(){
		var thisClass = this;
		Discourse.ajax("/qplum_api/score", {
		    dataType: 'json',		    
		    type: 'GET'
		}).then(function (data) {
			alert(data);
		    thisClass.score = data['score'];
		    thisClass.updateText(thisClass.score.toString());
		});		
	},

	updateText: function(text){		
		Ember.set(this, "text", text);		
	},

});

Discourse.PostEventButton = Discourse.ButtonView.extend({
	text: 'Send Event',
	title: 'Display the score of the user',		

	click: function(){		
		this.postEvent();			
	},


	renderIcon: function(buffer){
		buffer.push("<i class='icon icon-score-sign'></i>");
	},

	postEvent: function(){
		var thisClass = this;
		Discourse.ajax("/qplum_api/event", {
		    dataType: 'json',		    
		    type: 'POST',
		    data: {
		    	user_action: "sample_event",
		    	metadata: '{"1":2}'
		    }
		}).then(function (data) {
			
		});		
	},	

});

Discourse.TopicFooterButtonsView.reopen({
	addButtons: function(){
		this.attachViewClass(Discourse.ScoreButton);
		this.attachViewClass(Discourse.PostEventButton);
	}.on("additionalButtons")
});
if(Discourse.User.current())
{
}