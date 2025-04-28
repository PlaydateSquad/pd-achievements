const sortContainerSelector = ".game-grid"; // Selector for the container of items to sort
const filterBarSelector = "#filter-bar"; // Selector for target element of the sort and filter controls
const toggleButtonClass = "toggle"; // Class name applied to the sort direction toggle element
const defaultSort = "sortByDate"; // The default sort option

let sort = {
  direction: -1, // descending
  sortFn: defaultSort,

  init: function () {
    const searchInput = document.createElement("input");
    searchInput.type = "text";
    searchInput.classList.add("search");
    searchInput.placeholder = "Search…";

    searchInput.addEventListener("input", (event) => {
      const filter = event.target.value.toLowerCase();
      const list = document.querySelector(sortContainerSelector);

      [...list.children].forEach((node) => {
        if (
          filter.length == 0 ||
          node.dataset.title.toLowerCase().includes(filter) ||
          node.dataset.author.toLowerCase().includes(filter)
        ) {
          node.style.display = "block";
        } else {
          node.style.display = "none";
        }
      });
    });

    const select = document.createElement("select");

    const options = [
      { value: "sortByDate", label: "Date" }, // default comes first
      { value: "sortByTitle", label: "Title" },
      { value: "sortByAuthor", label: "Author" },
      { value: "sortByCount", label: "Achievements" },
    ];

    options.forEach((option) => {
      const opt = document.createElement("option");
      opt.value = option.value;
      opt.textContent = option.label;
      select.appendChild(opt);
    });

    select.addEventListener("change", (event) => {
      sort.sortFn = event.target.value;
      sort[sort.sortFn]();
    });

    const arrow = document.createElement("a");
    arrow.textContent = "↓"; // descending
    arrow.classList.add(toggleButtonClass);

    arrow.addEventListener("click", (event) => {
      sort.direction *= -1;
      event.target.innerText = sort.direction > 0 ? "↑" : "↓";
      sort[sort.sortFn](); // re-sort
    });

    const sortSelect = document.createElement("div");
    sortSelect.classList.add("sortSelect");
    sortSelect.appendChild(arrow);
    sortSelect.appendChild(select);

    const filterBar = document.querySelector(filterBarSelector);
    filterBar.appendChild(searchInput);
    filterBar.appendChild(sortSelect);

    // apply the intended default to the items on the page
    sort[sort.sortFn]();
  },

  sortByTitle: function () {
    const list = document.querySelector(sortContainerSelector);

    [...list.children]
      .sort((a, b) =>
        a.dataset.title.toLowerCase() > b.dataset.title.toLowerCase()
          ? sort.direction
          : -sort.direction
      )
      .forEach((node) => list.appendChild(node));
  },

  sortByAuthor: function () {
    const list = document.querySelector(sortContainerSelector);

    [...list.children]
      .sort((a, b) =>
        a.dataset.author.toLowerCase() > b.dataset.author.toLowerCase()
          ? sort.direction
          : -sort.direction
      )
      .forEach((node) => list.appendChild(node));
  },

  sortByCount: function () {
    const list = document.querySelector(sortContainerSelector);

    [...list.children]
      .sort((a, b) =>
        Number(a.dataset.achievementCount) > Number(b.dataset.achievementCount)
          ? sort.direction
          : -sort.direction
      )
      .forEach((node) => list.appendChild(node));
  },

  sortByDate: function () {
    const list = document.querySelector(sortContainerSelector);

    [...list.children]
      .sort((a, b) =>
        // sort by release date, or last added date if provided and more recent
        Math.max(
          new Date(a.dataset.releaseDate).getTime(),
          new Date(a.dataset.lastAddedDate).getTime() || 0
        ) >
        Math.max(
          new Date(b.dataset.releaseDate).getTime(),
          new Date(b.dataset.lastAddedDate).getTime() || 0
        )
          ? sort.direction
          : -sort.direction
      )
      .forEach((node) => list.appendChild(node));
  },
};
