Date.prototype.addDays = function (days) {
  var date = new Date(this.valueOf());
  date.setDate(date.getDate() + days);
  return date;
};

const newBadgeDays = 30; // Number of days to show the new badge after release date
const moreBadgeDays = 30; // Number of days to show the more badge after last update which added achievements

let badges = {
  add: function () {
    const games = document.querySelectorAll(".game");
    games.forEach((g) => {
      const releaseDate = new Date(g.dataset.releaseDate);
      const lastAddedDate = new Date(g.dataset.lastAddedDate);
      const now = new Date();
      if (releaseDate && now < releaseDate) {
        g.classList.add("badged", "badge-soon");
      } else if (lastAddedDate && now < lastAddedDate) {
        g.classList.add("badged", "badge-soon-released");
      } else if (releaseDate && now < releaseDate.addDays(newBadgeDays)) {
        g.classList.add("badged", "badge-new");
      } else if (lastAddedDate && now < lastAddedDate.addDays(moreBadgeDays)) {
        g.classList.add("badged", "badge-more");
      }
    });
  },
};
