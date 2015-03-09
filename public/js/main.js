$(function(){

	
	initEditor();
	$('.tag-input').each(function() {
		$(this).tagsInput({
			'height': '20px',
			'width': '340px',
			'defaultText': 'add tag'
		});
	})
	

	$("#post-cancel-btn").click(function() {
		$("#postModal").dialog("close");
	});
	$("#request-cancel-btn").click(function() {
		$("#requestModal").dialog("close");
	});
	$("#youtube-cancel-btn").click(function() {
		$("#youtubeModal").dialog("close");
	});
	$("#image-cancel-btn").click(function() {
		$("#imageModal").dialog("close");
	})


	if (parseInt($("#num-requests").html()) > 0)
		$("#num-requests").css('display', 'inline');

});

function openRequests() {
	num_requests = $("#num-requests").html() != '' ? $("#num-requests").html() : 0

	$.get('/users/getRequests/' + num_requests,
		function(data) {
			if (data != 'N/A') {
				$("#request-content").html(data);
				$("#requestModal").fadeIn(500).dialog({
					autoOpen:true,
					closeOnEscape:true,
					modal:true,
					resizable:false,
					width:600,
					height:350,
					position: {at:"top"},

				});
			}
		}
	);
}

function remove_tags(selector) {
	$(selector).importTags('');
}

function initEditor() {
	$('#editContents').editable({
		inlineMode: false,
		paragraphy: true,
		placeholder:"",
		width: "350px",
		height: "250px",
		buttons: ["indent", "outdent", "strikeThrough", "bold", "italic", "underline", "insertImage", "insertUnorderedList"],
		inverseSkin: true,
	});
}

function submitContents() {
	var content = $("#editContents").editable("getHTML").toString();

	if (isEmpty(content)) {
		alert("Your post is empty!");
		return false;
	}

	//need to get youtube url and convert into an iframe object. This is for embedding youtube videos in posts
	var youtube_match = parseYoutubeURL(content);
	if (youtube_match != null) {
		content = embedYoutube(youtube_match, content);
	}
	$("#htmlContent").val(content);
	$("#newPost").submit();
}

//checks whether content is empty, after stripping HTML tags
function isEmpty(content) {
	//if there are any images then the post is not empty
	if (content.indexOf('<img ') > 0)
		return false;

	//cheap hack to get text content
	var sanitized_content = $("<div>").html(content).text();
	//console.log("sanitized content = '" + sanitized_content + "'");
	
	if (sanitized_content == '')
		return true;
	return false;
}	
function openModal() {
	/*$("#postModal").fadeIn(500).modal({
		opacity:70, 
		overlayClose:true,
		position: ["25%", "25%"]
	});*/

	$("#postModal").fadeIn(500).dialog({
		autoOpen:true,
		closeOnEscape:true,
		modal:true,
		resizable:false,
		width:430,
		height:"auto",
		position: {at:"top"},
		close: function() {
			$("#editContents").editable("setHTML", "");
			remove_tags($("#tags"));
		}
	});
}

function getPostContents(pid, callback) {
	$.ajax({
		type: "GET",
		url: "/posts/" + pid + "/fetch",
		dataType: "json",
		success: function(data) {
			if (data.status != false) {
				callback(data);
			} 
		}
	});

}

//returns array of matches from the regex. These can be used to embed the video or whatever
function parseYoutubeURL(content) {
	var regEx = /^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#\&\?]*).*/;
	var match = content.match(regEx);
	//the youtube id will be in match[7]. can verify with console.log
	//console.log(match);

	return match;
}
function embedYoutube(match, content) {
	//strips html from the youtube id. the div is there because otherwise it will think the text is a selector
	var youtube_id = $("<div/>").html(match[7]).text();


	//replace youtube url with iframe object
	var youtube_vid = getYoutubeVideo(match[7]);

	//only going to work with youtube.com and youtu.be urls for now
	return content.replace(/http(s){0,1}:\/\/.*youtu(\.be|be\.com)\/.*/, youtube_vid);
}
function openNewModal(userID) {
	openModal();
	$("#newPost").attr("action", "/users/" + userID + "/posts");
	$("#blogSubmit").text("Post");
	$("#postModal").next().html("New Post");
}

function getYoutubeVideo(id) {
	if (id == '')
		return '';

	return '<iframe src="https://www.youtube.com/embed/' + id + '" width="375" height="211" frameborder="0" allowfullscreen></iframe>';
}