var entityMap = {
	'&': '&amp;',
	'<': '&lt;',
	'>': '&gt;',
	'"': '&quot;',
	"'": '&#39;',
	'/': '&#x2F;',
	'`': '&#x60;',
	'=': '&#x3D;'
};

var current_user = null;
var sidebar_open = false;

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


	if (parseInt($("#num-requests").html()) > 0) {
		$("#num-requests").css('display', 'inline');
	}

	$(document).click((event) => {
		if (!$(event.target).closest("#sidebar").length && !$(event.target).closest(".avatar").length) {
			if ($("#sidebar").is(":visible")) {
				sidebar_open = false;
				$("#sidebar").animate({width: "toggle"}, 350);	
			}
		}
	});
});

function updateImage(selector) {

	var reader = new FileReader();

	reader.onload = function (e) {
		console.log('image read!!!!');
		console.log(e.target.result);
		if (selector == '#avatar-upload') {
			console.log('hello?');
        	$('.sidebar.avatar').attr('src', e.target.result);	
		}
		else {
			console.log("changing banner....");
			$(".banner").css({
				"background-image": "url(" + e.target.result + ")"
			});
		}
    }

    console.log($(selector));

	reader.readAsDataURL($(selector)[0].files[0])
}

function deletePost(pID) {
	var r = confirm("Are you sure you want to delete this post?");

	if (r) {
		$.ajax({
			url: "/posts/" + pID + "/delete/",			
			type: "post",
			success: function(data) {
				//console.log(data);
				if (data == "success") {
					$("#post_" + pID).fadeOut(1000).slideUp(1000, function() {
						//this is setting the deleted post's content divider height to 0. otherwise it looks bad
						$("#post_"+ pID).next().hide();
					});

					//if we are in the dashboard view, hide the avatar as well
					if (location.href.indexOf('users') != -1) {
						$("#avatar_" + pID).hide();
					}
				}
				else {
					alert("an error has occurred");
				}
			}
		});
	}
}

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
				});
			}
		}
	);
}

function remove_tags(selector) {
	$(selector).importTags('');
}

function initEditor() {
	$('#editContents').froalaEditor({
		// inlineMode: false,
		// paragraphy: true,
		// placeholder:"",
		width: "350px",
		height: "250px",
		//toolbarButtons: ["indent", "outdent", "strikeThrough", "bold", "italic", "underline", "insertImage", "insertUnorderedList"],
		toolbarButtons: ['indent', 'outdent', 'quote', '|', 'strikeThrough', 'bold', 'italic', 'underline', '|', 'formatUL', 'formatOL', '|', 'insertImage' ],
		// inverseSkin: true,
		theme: 'dark',
		imageUploadURL: '/posts/upload_image',
		imageUploadMethod: 'Post'
	});
}

function submitContents() {
	var content = $("#editContents").froalaEditor("html.get");

	if (isEmpty(content)) {
		alert("Your post is empty!");
		return false;
	}

	//need to get youtube url and convert into an iframe object. This is for embedding youtube videos in posts
	if (content.indexOf('<iframe') == -1) {
		var youtube_match = parseYoutubeURL(content);
		if (youtube_match != null) {
			content = embedYoutube(youtube_match, content);
		}
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
		close: function() {
			$("#editContents").froalaEditor("html.set", "");
			remove_tags($("#tags"));
		}
	});
}

function open_sidebar(user_id) {
	if (!sidebar_open || current_user == user_id) {
		sidebar_open = sidebar_open ? false : true;
		$("#sidebar").animate({width: "toggle"}, 350);
		
	}

	$("#sidebar").css('background', '');
	
	current_user = user_id;

	$("#sidebar-loading").show();
	$.get(
		'/users/fetch_sidebar_posts?user_id=' + user_id,
		function(data) {
			$("#sidebar-loading").hide();
			if (data != 'false') {
				$("#sidebar").html(data);
			}
			else {
				console.log("an error occurred");
			}
		}
	);
}

function open_file_dialog(selector) {
	$(selector).click();
}

function edit_sidebar_settings() {
	$(".edit-sidebar").hide();
	$(".hidden-sidebar-button").show();
	$('.color-picker').show();
	$('.edit-banner').show();
	$(".sidebar-edit").show();

}

function hide_sidebar_settings() {
	$(".edit-sidebar").show();
	$(".hidden-sidebar-button").hide();
	$(".color-picker").hide();
	$(".edit-banner").hide();
	$(".sidebar-edit").hide();
}



function cancel_sidebar_settings(text_color, background_color) {
	hide_sidebar_settings();

	$("#sidebar").css('background', background_color);
	$(".sidebar-text").css('color', text_color);
}
function save_sidebar_settings() {

	var formData = new FormData();

	formData.append('text_color', $("#text-color").val());
	formData.append('background_color', $("#background-color").val());

	if ($("#avatar-upload")[0].files[0]) {
		formData.append('avatar', $("#avatar-upload")[0].files[0]);
	}
	if ($("#banner-upload")[0].files[0]) {
		formData.append('banner', $("#banner-upload")[0].files[0]);
	}

	$("#sidebar-loading").show();
	$.ajax({
		url: '/users/save_sidebar_settings',
		type: 'POST',
		data: formData,
		success: function(data) {
			if (data.success) {
				console.log("Success!");
			}
			else {
				console.log("failure :(")
			}
			$("#sidebar-loading").hide();
			hide_sidebar_settings();
		},
		cache: false,
		contentType: false,
		processData: false
	})
}

function escapeHtml(string) {
  	return String(string).replace(/[&<>"'`=\/]/g, function (s) {
    	return entityMap[s];
  	});
}

function getPostContents(pid, callback) {
	$.ajax({
		type: "GET",
		url: "/posts/" + pid + "/fetch",
		dataType: "json",
		success: function(data) {
			if (data.status) {
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
	var youtube_vid = getYoutubeVideo(youtube_id);

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