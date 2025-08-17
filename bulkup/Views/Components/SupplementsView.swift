struct SupplementsView: View {
    let supplements: [Supplement]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Suplementos")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Spacer()
            }
            
            // Vista de tabla para pantallas grandes, lista para pantallas pequeñas
            GeometryReader { geometry in
                if geometry.size.width > 600 {
                    supplementsTable
                } else {
                    supplementsList
                }
            }
            .frame(minHeight: CGFloat(supplements.count * 60))
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var supplementsTable: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Nombre")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Dosis")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Momento")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Frecuencia")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .background(Color.green.opacity(0.1))
            .cornerRadius(6)
            
            // Rows
            ForEach(supplements.indices, id: \.self) { index in
                HStack {
                    Text(supplements[index].name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(supplements[index].dosage)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(supplements[index].timing)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(supplements[index].frequency)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)
                .background(index % 2 == 0 ? Color.clear : Color.green.opacity(0.05))
            }
        }
    }
    
    private var supplementsList: some View {
        VStack(spacing: 12) {
            ForEach(supplements.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: 8) {
                    Text(supplements[index].name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Dosis:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text(supplements[index].dosage)
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("Momento:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text(supplements[index].timing)
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("Frecuencia:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text(supplements[index].frequency)
                                .font(.caption)
                        }
                        
                        if let notes = supplements[index].notes {
                            HStack(alignment: .top) {
                                Text("Notas:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                Text(notes)
                                    .font(.caption)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.6))
                .cornerRadius(8)
            }
        }
    }
}