const vm = new Vue({
    el: '#app',
    data: {
        results: []
    },
    mounted: function () {
        this.interval()
    },
    watch: {
        results: function () {
            var elem = this.$el.querySelector('#main')
            elem.scrollTop = elem.scrollHeight
        }
    },
    methods: {
        interval: function () {
            var results = this.results
            setInterval(function () {
                axios.get("http://localhost:8080/api")
                    .then(function (response) {
                        results.push(response.data)
                    })
            }, 1000);
        }
    }
});
