module FaradayMiddleware::AwsSigV4Util
  def normalize_for_net_http!(env)
    # `net/http` forcibly adds a `Accept-Encoding` header.
    # see https://github.com/ruby/ruby/blob/v2_4_2/lib/net/http/generic_request.rb#L39
    # If you do not want you to add a `Accept-Encoding` header,
    # explicitly set the header or use an adapter other than `net/http`.
    if Net::HTTP::HAVE_ZLIB
      env.request_headers['Accept-Encoding'] ||= 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3'
    end

    env.request_headers['Accept'] ||= '*/*'
    env
  end

  def seahorse_encode_query(url)
    return url unless url.query

    params = URI.decode_www_form(url.query)

    if params.any? {|_, v| v[?\s] }
      url = url.dup
      url.query = seahorse_encode_www_form(params)
    end

    url
  end

  def seahorse_encode_www_form(params)
    params.flat_map {|key, value|
      encoded_key = URI.encode_www_form_component(key)

      if value.nil?
        encoded_key
      else
        Array(value).map do |v|
          if v.nil?
            # nothing to do
          else
            encoded_key + '=' + Aws::Sigv4::Signer.uri_escape(v)
          end
        end
      end
    }.join(?&)
  end
end
