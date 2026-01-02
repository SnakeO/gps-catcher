# Steepfile - Configuration for Steep type checker
#
# Validate signatures: bundle exec rbs -I sig validate
# Type check: bundle exec steep check
#
# Note: Steep has issues loading with Rails. For now, use rbs validate
# to verify type signatures are syntactically correct.

target :app do
  # Load type signatures from sig directory
  signature "sig"

  # Check these source files
  check "app/value_objects"
  check "app/decoders"
  check "app/factories"
  check "app/repositories"
  check "app/services"

  # Standard library types
  library "time"
  library "json"
  library "digest"
end
