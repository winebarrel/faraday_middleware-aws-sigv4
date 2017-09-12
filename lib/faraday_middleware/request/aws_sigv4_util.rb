module FaradayMiddleware::AwsSigV4Util
  def normalize_for_net_http!(env)
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
    params.map {|key, value|
      encoded_key = URI.encode_www_form_component(key)

      if value.nil?
        encoded_key
      elsif value.respond_to?(:to_ary)
        value.to_ary.map {|v|
          if v.nil?
            encoded_key
          else
            encoded_key + '=' + Aws::Sigv4::Signer.uri_escape(v)
          end
        }.join('&')
      else
        encoded_key + '=' + Aws::Sigv4::Signer.uri_escape(value)
      end
    }.join('&')
  end
end
