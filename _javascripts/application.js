$(document).on('click', '.install-options a', function(e) {
  e.preventDefault();
  $(this).siblings().addClass('active');
  $(this).removeClass('active');
  $(this).tab('show');
});

$(function() {
});
