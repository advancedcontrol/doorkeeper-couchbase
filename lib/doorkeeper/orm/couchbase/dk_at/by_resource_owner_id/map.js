function(doc) {
  if(doc.type === 'dk_at' && doc.resource_owner_id && !doc.revoked_at) {
    emit([doc.resource_owner_id], null);
  }
}
