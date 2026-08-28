KEMENTERIAN PENDIDIKAN TINGGI, SAINS, DAN TEKNOLOGI
REPUBLIK INDONESIA
UNIVERSITAS SUMATERA UTARA
FAKULTAS ILMU KOMPUTER DAN TEKNOLOGI INFORMASI
PROGRAM STUDI S1 ILMU KOMPUTER
Jalan Universitas No. 9 Kampus USU, Kec. Medan Baru, Medan 20155
Tel/Fax: 061 8228048, e-mail: ilkom@usu.ac.id, laman: http://ilkom.usu.ac.id
=
FORM PENGAJUAN JUDUL
Nama : Richard Fajar Christian
NIM : 221401122
Judul diajukan oleh* : Dosen
Mahasiswa
Bidang Ilmu (tulis dua bidang) :
Uji Kelayakan Judul** : Diterima Ditolak
Hasil Uji Kelayakan Judul :
Calon Dosen Pembimbing I:
Prof. Drs. Poltak Sihombing M.Kom., Ph.D
NIP. 196203171991031001
Calon Dosen Pembimbing II:
Dr. Handrizal, S.Si., M.Comp.Sc
NIP. 197706132017061001
Medan, 19 Januari 2026
Ka. Laboratorium Penelitian
* Centang salah satu atau keduanya Fanindia Purnamasari S.TI., M.IT
** Pilih salah satu NIP. 198908172019032023
IoT dan AI
Foto Terbaru
Paraf Calon Pembimbing 1
Paraf Calon Pembimbing 2
KEMENTERIAN PENDIDIKAN TINGGI, SAINS, DAN TEKNOLOGI
REPUBLIK INDONESIA
UNIVERSITAS SUMATERA UTARA
FAKULTAS ILMU KOMPUTER DAN TEKNOLOGI INFORMASI
PROGRAM STUDI S1 ILMU KOMPUTER
Jalan Universitas No. 9 Kampus USU, Kec. Medan Baru, Medan 20155
Tel/Fax: 061 8228048, e-mail: ilkom@usu.ac.id, laman: http://ilkom.usu.ac.id
RINGKASAN JUDUL YANG DIAJUKAN
Judul / Topik Skripsi Pengembangan Smart Medicine Dispenser Berbasis IoT dengan Chatbot Intent
Classification Menggunakan Support Vector Machine untuk Pengelolaan
Pengingat Obat
Latar Belakang dan
Penelitian Terdahulu
Penurunan fungsi kognitif pada lansia dan padatnya aktivitas harian sering
menghambat kepatuhan konsumsi obat, sehingga diperlukan solusi teknologi
presisi untuk meminimalkan risiko medis. Upaya mengatasi masalah ini telah
dilakukan melalui integrasi teknologi Internet of Things (IoT), namun tantangan
utama terletak pada antarmuka pengguna. Penelitian oleh Hidayat dan Irianto
(2025) pada sistem AutoMedic menunjukkan bahwa meskipun dispenser obat
otomatis dapat memberikan notifikasi, kelompok lansia masih mengalami
kesulitan signifikan dalam mengatur jadwal obat melalui aplikasi seluler
dikarenakan keterbatasan dalam memahami antarmuka yang kompleks. Selain
itu, Paul et al. (2024) mengembangkan sistem yang memanfaatkan panggilan
telepon via GSM untuk memberikan peringatan yang lebih intrusif
dibandingkan sekadar notifikasi aplikasi. Meskipun inovatif, pendekatan ini
masih memiliki keterbatasan karena sangat bergantung pada perangkat eksternal
dan sinyal seluler yang mungkin tidak selalu berada dalam jangkauan pengguna
lansia.
Di sisi lain, pendekatan keamanan yang ketat juga telah dikembangkan untuk
mencegah kesalahan pengambilan obat. Roumaissa dan Rachid (2022)
mengusulkan sistem manajemen obat dengan mekanisme pemrograman terpusat
dan mode penguncian, di mana pengaturan jadwal dilakukan secara nirkabel
oleh tenaga kesehatan untuk meminimalkan risiko kesalahan pengguna.
Meskipun efektif dalam aspek kontrol, interaksi pada sistem semacam ini masih
cenderung kaku dan menambah kompleksitas operasional. Pengembangan
inovatif pada perangkat keras juga ditunjukkan oleh Dayananda dan Upadhya
(2024) melalui sistem SPEC 2.0 yang menerapkan mekanisme pencegahan
overdosis dengan mendeteksi dan memisahkan obat yang tidak diambil. Namun,
mayoritas penelitian terdahulu ini masih berfokus pada otomasi perangkat keras
dan keamanan fisik, sementara aspek kemudahan interaksi verbal dan efisiensi
pemrosesan perintah belum sepenuhnya terakomodasi.
Dalam aspek pengendalian sistem berbasis kecerdasan buatan, penentuan
metode klasifikasi perintah (intent classification) menjadi tahapan krusial dalam
sistem percakapan modern (Menda & Keerthi, 2022). Akan tetapi, mendeteksi
intent pengguna secara akurat merupakan tugas yang kompleks (Weld et al.,
2023). Terkait performa model, Ouaddi et al. (2025) melaporkan bahwa model
KEMENTERIAN PENDIDIKAN TINGGI, SAINS, DAN TEKNOLOGI
REPUBLIK INDONESIA
UNIVERSITAS SUMATERA UTARA
FAKULTAS ILMU KOMPUTER DAN TEKNOLOGI INFORMASI
PROGRAM STUDI S1 ILMU KOMPUTER
Jalan Universitas No. 9 Kampus USU, Kec. Medan Baru, Medan 20155
Tel/Fax: 061 8228048, e-mail: ilkom@usu.ac.id, laman: http://ilkom.usu.ac.id
bahasa berskala besar (Large Language Models) memang memiliki akurasi
tinggi, namun menuntut sumber daya komputasi masif sehingga kurang efisien
untuk perangkat embedded. Hal ini diperkuat oleh studi Santosa et al. (2025)
dan Wahba et al. (2023) yang membandingkan algoritma klasifikasi teks; studi
tersebut menemukan bahwa model Support Vector Machine (SVM) mampu
mencapai akurasi yang kompetitif dibandingkan model berbasis transformer
(seperti IndoBERT) dengan kebutuhan sumber daya yang jauh lebih rendah.
Temuan ini sejalan dengan tinjauan Jemimah et al. (2025) yang menyoroti
relevansi SVM untuk domain tertutup karena efisiensinya, terutama jika
didukung oleh persiapan data yang optimal sebagaimana disarankan oleh
Kowalczuk dan Kuligowska (2024). Karakteristik ini menjadikan SVM sebagai
alternatif ideal untuk implementasi pada sistem IoT yang menuntut
responsivitas tinggi tanpa membebani perangkat keras.
Berdasarkan kajian literatur tersebut, disimpulkan bahwa masih terbatas
penelitian yang mengintegrasikan kemudahan penggunaan bagi caregiver,
pemanfaatan input berbasis suara (voice command), serta klasifikasi intent
Bahasa Indonesia menggunakan SVM yang efisien dalam satu kerangka kerja
IoT. Selain itu, Roumaissa dan Rachid (2022) turut merekomendasikan
pengembangan lanjut berupa penambahan speaker untuk umpan balik yang
lebih informatif. Berangkat dari celah penelitian tersebut, penelitian ini
mengusulkan integrasi sistem notifikasi berbasis suara melalui speaker dan
deteksi intent menggunakan SVM. Kombinasi ini diharapkan mampu
menyederhanakan proses interaksi, meningkatkan aksesibilitas bagi pengguna
rentan, serta memungkinkan implementasi sistem cerdas pada perangkat IoT
dengan sumber daya terbatas.
Rumusan Masalah Berdasarkan latar belakang yang telah diuraikan, rumusan masalah dalam
penelitian ini difokuskan pada upaya mengatasi keterbatasan interaksi dan
efisiensi komputasi pada sistem manajemen obat yang ada saat ini. Mayoritas
penelitian terdahulu lebih menitikberatkan pada pengembangan otomasi
perangkat keras atau keamanan akses fisik, namun belum optimal dalam
menyediakan metode interaksi yang intuitif bagi pengguna dengan keterbatasan
teknis. Meskipun teknologi Large Language Models (LLM) menawarkan
akurasi tinggi, implementasinya pada perangkat IoT terkendala oleh kebutuhan
sumber daya yang besar. Oleh karena itu, permasalahan utama yang diangkat
adalah bagaimana merancang sistem kendali perangkat IoT yang cerdas namun
efisien menggunakan algoritma Support Vector Machine (SVM) untuk
klasifikasi intent.
KEMENTERIAN PENDIDIKAN TINGGI, SAINS, DAN TEKNOLOGI
REPUBLIK INDONESIA
UNIVERSITAS SUMATERA UTARA
FAKULTAS ILMU KOMPUTER DAN TEKNOLOGI INFORMASI
PROGRAM STUDI S1 ILMU KOMPUTER
Jalan Universitas No. 9 Kampus USU, Kec. Medan Baru, Medan 20155
Tel/Fax: 061 8228048, e-mail: ilkom@usu.ac.id, laman: http://ilkom.usu.ac.id
Tantangan teknis selanjutnya terletak pada arsitektur integrasi antara antarmuka
chatbot dan perangkat fisik. Mengingat perintah suara (voice command)
diposisikan sebagai variasi masukan untuk meningkatkan aksesibilitas,
permasalahan mendasar bukan pada pengolahan sinyal suara, melainkan pada
bagaimana sistem menerjemahkan hasil klasifikasi intent tersebut menjadi
instruksi eksekusi yang presisi pada mikrokontroler. Selain itu, evaluasi
terhadap kinerja integrasi ini menjadi krusial, mengingat belum banyaknya studi
yang mengukur keseimbangan antara akurasi klasifikasi pada dataset terbatas
dengan efisiensi operasional sistem dalam konteks manajemen obat cerdas.
Metodologi 1. Studi Pustaka
Tahap ini diawali dengan studi literatur secara komprehensif melalui
pengumpulan referensi dari berbagai sumber ilmiah bereputasi, meliputi
jurnal internasional, prosiding konferensi, buku teks, dan repositori
penelitian yang relevan. Kajian difokuskan pada topik utama seperti
Internet of Things (IoT), pengembangan chatbot berbasis klasifikasi
intent, protokol komunikasi berbasis REST API, serta penerapan
algoritma Support Vector Machine (SVM) pada sistem dengan domain
perintah terbatas. Selain itu, studi ini juga mengelaborasi penelitian
terdahulu mengenai pengembangan dispenser obat pintar, sistem
monitoring kesehatan berbasis IoT, serta pemanfaatan modul ESP32
sebagai mikrokontroler utama dalam sistem otomasi. Kajian teknis turut
dilakukan terhadap arsitektur client-server berbasis Virtual Private
Server (VPS) dan implementasi aplikasi mobile sebagai antarmuka
pengguna (user interface).
2. Analisis dan Perancangan Sistem
Tahap ini difokuskan pada analisis kebutuhan secara mendalam serta
perancangan komponen-komponen vital dalam ekosistem sistem
manajemen obat berbasis Internet of Things (IoT) yang terintegrasi
dengan chatbot. Proses analisis dilakukan untuk mengidentifikasi
kebutuhan fungsional dan non-fungsional sistem, yang mencakup
mekanisme komunikasi data antara aplikasi mobile, server, dan
perangkat IoT, alur interaksi chatbot, serta proses klasifikasi intent
menggunakan metode Support Vector Machine (SVM). Selanjutnya,
pada tahap perancangan, disusun arsitektur sistem terintegrasi yang
menempatkan modul ESP32 sebagai perangkat kendali IoT, Virtual
Private Server (VPS) sebagai backend server sekaligus engine untuk
pemrosesan chatbot, serta aplikasi mobile sebagai antarmuka utama
bagi pengguna. Perancangan teknis ini juga meliputi spesifikasi alur
komunikasi data antar-komponen menggunakan protokol REST API,
KEMENTERIAN PENDIDIKAN TINGGI, SAINS, DAN TEKNOLOGI
REPUBLIK INDONESIA
UNIVERSITAS SUMATERA UTARA
FAKULTAS ILMU KOMPUTER DAN TEKNOLOGI INFORMASI
PROGRAM STUDI S1 ILMU KOMPUTER
Jalan Universitas No. 9 Kampus USU, Kec. Medan Baru, Medan 20155
Tel/Fax: 061 8228048, e-mail: ilkom@usu.ac.id, laman: http://ilkom.usu.ac.id
penyusunan dataset intent beserta proses ekstraksi fitur untuk pelatihan
model SVM, serta perancangan struktur database yang sistematis untuk
pengelolaan data esensial seperti log aktivitas, jadwal konsumsi obat,
status konektivitas perangkat, dan riwayat interaksi pengguna. Seluruh
hasil analisis kebutuhan dan skema hubungan antar-komponen dalam
sistem ini divisualisasikan melalui diagram arsitektur penelitian yang
dapat dilihat pada Gambar 1.
Gambar 1. Arsitektur Penelitian
3. Implementasi Sistem
Pada tahap ini, hasil rancangan sistem direalisasikan melalui
pengembangan perangkat keras dan perangkat lunak. Mikrokontroler
ESP32 dikonfigurasi untuk berkomunikasi dengan server menggunakan
protokol HTTP. Di sisi server, dilakukan pembangunan chatbot engine
dan model klasifikasi Support Vector Machine (SVM) menggunakan
bahasa pemrograman Python, yang dijalankan pada Virtual Private
Server (VPS) dan terintegrasi dengan sistem manajemen database.
Sementara itu, aplikasi mobile dikembangkan untuk menyediakan
antarmuka chatbot serta dashboard sederhana yang memungkinkan
pengguna mengirim perintah, memantau status dispenser, dan meninjau
riwayat (history) aktivitas. Integrasi sistem dilakukan melalui pengujian
KEMENTERIAN PENDIDIKAN TINGGI, SAINS, DAN TEKNOLOGI
REPUBLIK INDONESIA
UNIVERSITAS SUMATERA UTARA
FAKULTAS ILMU KOMPUTER DAN TEKNOLOGI INFORMASI
PROGRAM STUDI S1 ILMU KOMPUTER
Jalan Universitas No. 9 Kampus USU, Kec. Medan Baru, Medan 20155
Tel/Fax: 061 8228048, e-mail: ilkom@usu.ac.id, laman: http://ilkom.usu.ac.id
komunikasi end-to-end antara aplikasi mobile, server, dan perangkat
ESP32 guna memastikan sistem berjalan secara fungsional dan
responsif.
4. Pengujian Sistem
Pengujian sistem dilaksanakan untuk mengevaluasi kinerja dan
keandalan sistem secara komprehensif. Pengujian fungsional
menerapkan pendekatan black-box testing untuk memverifikasi bahwa
setiap fitur sistem beroperasi sesuai spesifikasi kebutuhan, mencakup
pengiriman perintah melalui chatbot, respons sistem, hingga eksekusi
mekanis dispenser obat. Evaluasi kinerja model klasifikasi intent
berbasis SVM dilakukan melalui pengukuran metrik accuracy,
precision, recall, dan F1-score pada dataset terbatas. Selain itu,
efisiensi komputasi sistem diuji dengan menganalisis waktu eksekusi
perintah, konsumsi memori dan CPU pada VPS maupun ESP32, serta
reliabilitas komunikasi jaringan.
5. Dokumentasi
Seluruh rangkaian kegiatan penelitian, mulai dari studi pustaka, analisis
dan perancangan, implementasi, hingga pengujian, didokumentasikan
secara sistematis dalam laporan penelitian. Dokumentasi ini mencakup
diagram arsitektur sistem, alur proses, struktur database, cuplikan kode
program (source code), hasil pengujian, serta analisis performa sistem.
Penyusunan dokumentasi bertujuan untuk menjamin transparansi
proses penelitian, memfasilitasi proses evaluasi, serta memungkinkan
penelitian untuk direplikasi atau dikembangkan lebih lanjut di masa
mendatang.
Referensi 1. Dayananda, P., & Upadhya, A. G. (2024). Development of Smart Pill
Expert System Based on IoT. Journal of The Institution of Engineers
(India): Series B, 105(3), 457–467. https://doi.org/10.1007/s40031-
023-00956-2
2. Hidayat, M. L., & Irianto, K. D. (2025). AutoMedic: Framework of
Automatic Pill Dispenser System with Human Centered Design
Method. International Journal of Informatics and Computation
(IJICOM), 7(2), 2025. https://doi.org/10.35842/ijicom
3. Jemimah, K., Kannan, R., & Andres, F. (2025). Intent detection in AI
chatbots: a comprehensive review of techniques and the role of external
knowledge. IAES International Journal of Artificial Intelligence, 14(5),
4250–4259. https://doi.org/10.11591/ijai.v14.i5.pp4250-4259
4. Kowalczuk, B., & Kuligowska, K. (2024). Enhancing Chatbot Intent
Classification using Active Learning Pipeline for Optimized Data
KEMENTERIAN PENDIDIKAN TINGGI, SAINS, DAN TEKNOLOGI
REPUBLIK INDONESIA
UNIVERSITAS SUMATERA UTARA
FAKULTAS ILMU KOMPUTER DAN TEKNOLOGI INFORMASI
PROGRAM STUDI S1 ILMU KOMPUTER
Jalan Universitas No. 9 Kampus USU, Kec. Medan Baru, Medan 20155
Tel/Fax: 061 8228048, e-mail: ilkom@usu.ac.id, laman: http://ilkom.usu.ac.id
Preparation. Journal of Applied Economic Sciences (JAES), 19(16),
317. https://doi.org/10.57017/jaes.v19.3(85).07
5. Menda, M., & Keerthi, G. S. (2022). Intent Classification in
Conversational System using Machine Learning Techniques. In
International Journal of Computer Applications (Vol. 183, Issue 51).
https://www.ijcaonline.org/archives/volume183/number51/menda2022-ijca-921913.pdf
6. Ouaddi, C., Benaddi, L., Bouziane, E. mahi, Naimi, L., Rahouti, M.,
Jakimi, A., & Saadane, R. (2025). Assessing the effectiveness of large
language models for intent detection in tourism chatbots: A
comparative analysis and performance evaluation. Scientific African,
28. https://doi.org/10.1016/j.sciaf.2025.e02649
7. Paul, L. C., Ahmed, S. S., Rani, T., Haque, M. A., Roy, T. K., Hossain,
M. N., & Hossain, M. A. (2024). A smart medicine reminder kit with
mobile phone calls and some health monitoring features for senior
citizens. Heliyon, 10(4). https://doi.org/10.1016/j.heliyon.2024.e26308
8. Roumaissa, B., & Rachid, B. (2022). An IoT-Based Pill Management
System for Elderly. Informatica (Slovenia), 46(4), 457–468.
https://doi.org/10.31449/inf.v46i4.4195
9. Santosa, R., Nusantara, A. B., & Imron, S. (2025). Comparative
Analysis of SVM and IndoBERT for Intent Classification in
Indonesian Overtime Chatbots. Journal of System and Computer
Engineering (JSCE), 6(3), 258–270.
https://doi.org/10.61628/jsce.v6i3.2058
10. Wahba, Y., Madhavji, N., & Steinbacher, J. (2023). A Comparison of
SVM Against Pre-trained Language Models (PLMs) for Text
Classification Tasks. Lecture Notes in Computer Science (Including
Subseries Lecture Notes in Artificial Intelligence and Lecture Notes in
Bioinformatics), 13811 LNCS, 304–313. https://doi.org/10.1007/978-3-
031-25891-6_23
11. Weld, H., Huang, X., Long, S., Poon, J., & Han, S. C. (2023). A
Survey of Joint Intent Detection and Slot Filling Models in Natural
Language Understanding. ACM Computing Surveys, 55(8).
https://doi.org/10.1145/3547138
Medan, 19 Januari 2026
Mahasiswa yang mengajukan,
Richard Fajar Christian
NIM. 221401122