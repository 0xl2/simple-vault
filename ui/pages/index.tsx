import { PageHeader } from "../components/main/PageHeader";
import { VaultMain } from "../components/vault/VaultMain"

function list() {
  return (
    <div className="flex flex-col min-h-screen bg-gradient-to-br from-gray-300 to-sky-200">
      <PageHeader />
      <div className="container mx-auto bg-white p-5 rounded mt-3">
        <VaultMain />
      </div>
    </div>
  );
}

export default list;
