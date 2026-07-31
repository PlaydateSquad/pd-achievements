Date.prototype.addDays = function (days) {
  var date = new Date(this.valueOf());
  date.setDate(date.getDate() + days);
  return date;
};

const newBadgeDays = 30; // Number of days to show the new badge after achievements first become available
const moreBadgeDays = 30; // Number of days to show the more badge after last update which added achievements

// Reads a YYYY-MM-DD data attribute, yielding null when it's absent or malformed
const parseDate = function (value) {
  const date = value ? new Date(value) : null;
  return date && !isNaN(date.getTime()) ? date : null;
};

const laterOf = function (date, otherDate) {
  return otherDate && otherDate > date ? otherDate : date;
};

let badges = {
  add: function () {
    const games = document.querySelectorAll(".game");
    games.forEach((g) => {
      const now = new Date();
      const releaseDate = parseDate(g.dataset.releaseDate);

      if (!releaseDate) {
        g.dataset.badgeGroup = 3;
        return;
      }

      // The date achievements first became — or will become — available. Games that shipped
      // with achievements don't provide a first-added date, so theirs arrived at release.
      const debutDate = laterOf(releaseDate, parseDate(g.dataset.firstAddedDate));
      // The date achievements were most recently added, which can't precede their debut.
      const lastAddedDate = laterOf(debutDate, parseDate(g.dataset.lastAddedDate));

      if (now < releaseDate) {
        // hasn't released yet, and will arrive with achievements
        g.classList.add("badged", "badge-soon");
        g.dataset.badgeGroup = 5;
      } else if (now < debutDate) {
        // playable now, but its achievements haven't arrived yet
        g.classList.add("badged", "badge-soon-released");
        g.dataset.badgeGroup = 4;
      } else if (now < debutDate.addDays(newBadgeDays)) {
        // achievements arrived recently, whether at release or long after it
        g.classList.add("badged", "badge-new");
        g.dataset.badgeGroup = 1;
      } else if (lastAddedDate <= now && now < lastAddedDate.addDays(moreBadgeDays)) {
        // achievements were expanded recently; additions still to come go unbadged until they land
        g.classList.add("badged", "badge-more");
        g.dataset.badgeGroup = 2;
      } else {
        g.dataset.badgeGroup = 3;
      }

      // The date this game's badge hinges on, for sorting. Additions that haven't happened yet
      // don't count, but achievements still to arrive are all a soon-badged game has to sort by.
      g.dataset.sortDate = (
        lastAddedDate <= now ? lastAddedDate : debutDate
      ).getTime();
    });
  },
};
