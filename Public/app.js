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
