let EventEmitter = require('events');

let event = new EventEmitter();

event.on("event1", function () {
  console.log("Event1 fired!");
  setTimeout(function () {
    event.emit("event2");
  }, 1000);
});

event.on("event2", function () {
  console.log("Event2 fired!");
  setTimeout(function () {
    event.emit("event1");
  }, 500);
});

event.on("event3", function () {
  console.log("Event3 fired!");
  process.nextTick(function () {
    event.emit("event1");
  });
});

event.emit("event3");
