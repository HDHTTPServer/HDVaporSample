const vm = new Vue({
    el: '#app',
    data: {
        results: []
    },
    mounted: function () {
      this.interval()
    },
    methods: {
        interval: function () {
            let timer = setInterval(() => {
                axios.get("http://localhost:8080/api")
                    .then(response => this.results.push(response.data))
            }, 1000);
        }
    }
});
