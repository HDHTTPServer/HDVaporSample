import Vapor
import HTTP
import Sessions

final class ApiController: ResourceRepresentable {

    /// GET /api
    func index(_ req: Request) throws -> ResponseRepresentable {
        let session = try req.assertSession()
        var counter = session.data["counter"]?.int ?? 0
        let data = counter.description
//        let data = NumberUtilities.fibonacci(counter)
        counter += 1
        try session.data.set("counter", counter)

        var json = JSON()
        try json.set("data", data)
        return json
    }

    func makeResource() -> Resource<String> {
        return Resource(
                index: index
        )
    }
}

extension ApiController: EmptyInitializable {
}
