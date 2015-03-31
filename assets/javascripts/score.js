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

Discourse.TopicFooterButtonsView.reopen({
	addScoreButton: function(){
		this.attachViewClass(Discourse.ScoreButton);
	}.on("additionalButtons")
});
if(Discourse.User.current())
{
}