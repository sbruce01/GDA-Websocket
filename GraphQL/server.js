const { createServer } = require('graphql-yoga')
const fetch = (...args) =>
  import('node-fetch').then(({ default: fetch }) => fetch(...args));

const baseURL = `http://localhost:5005`

const resolvers = {
    Query: {
      data: () => {
        return fetch(`${baseURL}/getData`).then(res => res.json())
      },
      dataWithStartTime: (parent, args) => {
        const { startTime } = args
        return fetch(`${baseURL}/getData?sd=${startTime}`).then(res => res.json())
      },
      dataWithMultiple: (parent, args) => {
        const { startTime, exchange } = args
        return fetch(`${baseURL}/getData?exc=${exchange}&sd=${startTime}`).then(res => res.json())
      },
    },
  }

const server = createServer({
    schema: {
      typeDefs: `
        type Query {
            data: [Data!]!
            dataWithStartTime(startTime: String!): [Data!]!
            dataWithMultiple(startTime: String!, exchange: [String!]): [Data!]!
        }
        
        type Data {
            date: String!
            time: String!
            sym: String!
            orderID: String!
            price: Float!
            tradeID: String!
            side: String!
            size: Float!
            exchange: String!
        }
      `,
      resolvers: resolvers,
      },
  })

server.start(() => console.log(`Server is running on http://localhost:4000`))