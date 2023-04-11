var isCreator = false;

$(function () {
  window.addEventListener("message", function (event) {
    if (event.data.type == "open-ui") {
      openUi(true);
    }
  });
});

function openUi(bool) {
  if (bool) {
    $(".popup").css("display", "block");
    $(".card-container").css("display", "flex");
    setTimeout(function () {
      $(".popup").css("opacity", 1);
    }, 100);
    $("body").css("background-color", "rgba(0, 0, 0, 0.61)");
  } else {
    $(".card-container").css("display", "none");
    $(".popup").css("display", "none");
    $(".create-container").css("display", "none");
    $("body").css("background-color", "rgba(0, 0, 0, 0)");
    setTimeout(function () {
      $(".popup").css("opacity", 0);
    }, 100);
    $.post("https://i-tdm/close");
  }
}

function setupCreateMatchScreen(maps, isTdm) {
  //create ui here
  openUi(false);
  if (isTdm) {
    console.log("TDM");
  } else {
    selectedMap = maps[0];
    $.post(
      "https://i-tdm/startDeathMatch",
      JSON.stringify({ selectedMap, isCreator }),
      function (data) {
        //load HUD here
      }
    );
  }
}

$(document).on("click", "#create-btn", function (e) {
  $(".card-container").css("display", "none");
  $(".create-container").css("display", "flex");
  isCreator = true;
});

$(document).on("click", "#join-btn", function (e) {
  $(".create-container").css("display", "flex");
  $(".card-container").css("display", "none");
});

$(document).on("click", "#leader-board-btn", function (e) {
  //click leaderboard
});

$(document).on("click", "#back-btn-mode", function (e) {
  $(".create-container").css("display", "none");
  $(".card-container").css("display", "flex");
  isCreator = false;
});

$(document).on("click", "#create-dm", function (e) {
  $.post(
    "https://i-tdm/get-maps",
    JSON.stringify({ isTdm: false }),
    function (data) {
      setupCreateMatchScreen(data.maps, false);
    }
  );
});

$(document).on("click", "#create-tdm", function (e) {
  $.post(
    "https://i-tdm/get-maps",
    JSON.stringify({ isTdm: true }),
    function (data) {
      setupCreateMatchScreen(data.maps, true);
    }
  );
});

$(document).on("keydown", function () {
  if (event.keyCode == 27) {
    openUi(false);
  }
});
