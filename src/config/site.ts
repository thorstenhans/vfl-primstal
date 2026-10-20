import logoVfl from "../images/logo-vfl.png";

export const siteConfig = {
  club: {
    name: "VfL Primstal",
    fullName: "Verein für Leibesübungen Primstal e.V.",
    shortName: "VfL",
    foundedYear: 1931,
    location: "Nonnweiler-Primstal, Saarland",
    description:
      "Seit 1931 leben wir Fußball im Herzen des Saarlandes. Der VfL Primstal steht für Leidenschaft, Gemeinschaft und sportliche Exzellenz – auf dem Platz und abseits davon.",
    address: {
      name: "VfL Primstal e.V.",
      street: "Am Schwimmbad 10",
      city: "66620 Nonnweiler-Primstal",
    },
    stadium: {
      name: "Allerswaldstadion",
      fullAddress: "Am Schwimmbad 10, 66620 Nonnweiler-Primstal",
      mapsUrl: "https://www.google.com/maps/search/Allerswaldstadion+Primstal",
    },
    logoUrl: logoVfl.src,
  },
  social: {
    facebook: "https://www.facebook.com/vflprimstal",
    instagram: "https://www.instagram.com/vflprimstal",
  },
  nav: [
    {
      label: "Verein",
      href: "/vfl-primstal/verein",
      children: [
        { label: "Stadion", href: "/vfl-primstal/stadion" },
        { label: "Chronik", href: "/vfl-primstal/chronik" },
        { label: "Vorstand", href: "/vfl-primstal/vorstand" },
      ],
    },
    {
      label: "Teams",
      href: "/vfl-primstal/#teams",
      children: [
        { label: "1. Mannschaft", href: "/vfl-primstal/teams/1-mannschaft" },
        { label: "2. Mannschaft", href: "/vfl-primstal/teams/2-mannschaft" },
        { label: "Alte Herren", href: "/vfl-primstal/teams/alte-herren" },
      ],
    },
    {
      label: "Jugend",
      href: "/vfl-primstal/teams/jugend",
      children: [
        {
          label: "JFG Schaumberg-Prims",
          href: "/vfl-primstal/teams/jugend/jfg-schaumberg-prims",
        },
        {
          label: "VfL Primstal",
          href: "/vfl-primstal/teams/jugend/vfl-primstal",
        },
      ],
    },
    { label: "Kontakt", href: "/vfl-primstal/#contact" },
  ],
  teams: [
    {
      name: "1. Mannschaft",
      slug: "1-mannschaft",
      href: "/vfl-primstal/teams/1-mannschaft",
      league: "Verbandsliga Nord-Ost",
      description:
        "Unsere erste Mannschaft spielt in der Verbandsliga Nord-Ost – der zweithöchsten Amateurklasse des Saarlandes. Mit Leidenschaft und Teamgeist vertreten sie die Farben des VfL.",
      fupaUrl: "https://www.fupa.net/team/vfl-primstal-m1-2026-27",
    },
    {
      name: "2. Mannschaft",
      slug: "2-mannschaft",
      href: "/vfl-primstal/teams/2-mannschaft",
      league: "Landesliga Nord",
      description:
        "Die zweite Mannschaft ist in der Landesliga Nord aktiv. Sie bietet talentierten Spielern eine starke Wettkampfplattform und ist ein wichtiges Bindeglied im Vereinsleben.",
      fupaUrl: "https://www.fupa.net/team/vfl-primstal-m2-2026-27",
    },
    {
      name: "Jugend",
      slug: "jugend",
      href: "/vfl-primstal/teams/jugend",
      league: "VfL Primstal & JFG Schaumberg-Prims",
      description:
        "Nachwuchsförderung liegt uns am Herzen: Von der G- bis zur E-Jugend beim VfL Primstal und ab der D- bis zur A-Jugend in der JFG Schaumberg-Prims.",
    },
    {
      name: "Alte Herren",
      slug: "alte-herren",
      href: "/vfl-primstal/teams/alte-herren",
      league: "Freizeitfußball",
      description:
        "Fußball kennt kein Alter! Unsere Alten Herren halten die Leidenschaft für das runde Leder lebendig – mit jeder Menge Spaß und Kameradschaft.",
    },
  ],
  contact: {
    email: "info@vfl-primstal.de",
  },
  impressum: {
    clubName: "Verein für Leibesübungen 1931 Primstal e.V. (VfL Primstal e.V.)",
    street: "Am Schwimmbad 10",
    city: "66620 Nonnweiler-Primstal",
    responsible: "Timo Horn, Thomas Paulus, Christoph Holz (Präsidium / Vorstand gemäß § 26 BGB)",
    email: "info@vfl-primstal.de",
    registerCourt: "Amtsgericht St. Wendel",
    registerNumber: "VR 527",
  },
};
