function(doc) {
  if(doc.type === 'dk_at' && doc.application_id && doc.resource_owner_id && !doc.revoked_at) {
    // Will be ordered by created at desc by default
    emit([doc.application_id, doc.resource_owner_id], null);
  }
}
