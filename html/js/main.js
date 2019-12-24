var post = (url, data) => {
    var request = new XMLHttpRequest();
    request.open('POST', url, true);
    request.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');
    request.send(data);
}

var app = new Vue({
  el: '#app',
  data: {
    tracking: true,
    trackingItems: {
      entities: true,
      foliage: true,
      items: true,
      vehicles: true,
    }
  },
  methods: {
    toggle (name) {
      this.trackingItems[name] = !this.trackingItems[name]
      post('http://spanser_debug/set_tracking', JSON.stringify({
        key: `Track${name.charAt(0).toUpperCase()}${name.slice(1)}`,
        value: this.trackingItems[name]
      }))
    },
    ON_SET_TRACKED ({ entities, items, foliage, vehicles }) {
      this.trackingItems.entities = entities
      this.trackingItems.foliage = foliage
      this.trackingItems.items = items
      this.trackingItems.vehicles = vehicles
    }
  },
  destroyed() {
    clearInterval(this.focusTimer);
    window.removeEventListener('message', this.listener);
  },
  mounted() {
    post('http://spanser_debug/loaded', JSON.stringify({}))
    this.listener = window.addEventListener('message', (event) => {
      const item = event.data || event.detail
      if (this[item.type]) {
        this[item.type](item)
      }
    })
    window.addEventListener('keyup', e => {
      if (e.which === 27) {
        post('http://spanser_debug/close_ui', JSON.stringify({}))
      }
    })
  },
})
