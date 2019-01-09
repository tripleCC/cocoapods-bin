
module Pod
  class Validator
    # def validate_source_url(spec)
    #   return if spec.source.nil? || spec.source[:http].nil?
    #   url = URI(spec.source[:http])
    #   return if url.scheme == 'https' || url.scheme == 'file'
    #   warning('http', "The URL (`#{url}`) doesn't use the encrypted HTTPs protocol. " \
    #           'It is crucial for Pods to be transferred over a secure protocol to protect your users from man-in-the-middle attacks. '\
    #           'This will be an error in future releases. Please update the URL to use https.')
    # end

    def validate_source_url(spec)
    end
  end
end