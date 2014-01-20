class Chef
  class HTTP
    class RequestID

      def handle_request(method, url, headers={}, data=false)
        headers.merge!({'X-Ops-RequestId' => Chef::RunID.instance.run_id})
        [method, url, headers, data]
      end

      def handle_response(http_response, rest_request, return_value)
        [http_response, rest_request, return_value]
      end

      def stream_response_handler(response)
        nil
      end

    end
  end
end
